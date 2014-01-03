#
# Cookbook Name:: jenkins
# HWRP:: slave
#
# Author:: Seth Chisamore <schisamo@getchef.com>
#
# Copyright 2013, Chef Software, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'chef/resource'
require 'chef/provider'

#
#
#
class Chef
  class Resource::JenkinsSlave < Resource
    identity_attr :name

    attr_writer :exists
    attr_writer :connected
    attr_writer :online

    def initialize(name, run_context = nil)
      super

      @resource_name = :jenkins_slave

      # Set default actions and allowed actions
      @action = :create
      @allowed_actions.push(:create, :delete,
                            :connect, :disconnect,
                            :online, :offline)

      # Set the name attribute and default attributes
      @name            = name
      @remote_fs       = '/home/jenkins'
      @executors       = 1
      @usage_mode      = 'normal'
      @labels          = []
      @in_demand_delay = 0
      @idle_delay      = 1

      # State attributes that are set by the provider
      @exists    = false
      @connected = false
      @online    = false
    end

    #
    # The name of the slave.
    #
    # @param [String] arg
    # @return [String]
    #
    def name(arg = nil)
      set_or_return(:name, arg, kind_of: String)
    end

    #
    # The description of the slave.
    #
    # @param [String] arg
    # @return [String]
    #
    def description(arg = nil)
      set_or_return(:description, arg, kind_of: String)
    end

    #
    # The remote directory on the slave where the master will install
    # files required to run builds.
    #
    # @param [String] arg
    # @return [String]
    #
    def remote_fs(arg = nil)
      set_or_return(:remote_fs, arg, kind_of: String)
    end

    #
    # The number of executors for the slave. This controls the number of
    # concurrent builds that Jenkins can perform.
    #
    # @param [Integer] arg
    # @return [Integer]
    #
    def executors(arg = nil)
      set_or_return(:executors, arg, kind_of: Integer)
    end

    #
    # Controls how Jenkins schedules builds on this machine.
    #
    # @param [String] arg
    # @option arg [String] `exclusive` Utilize this slave as much as possible.
    # @option arg [String] `normal` Leave this machine for tied jobs only.
    # @return [String]
    #
    def usage_mode(arg = nil)
      set_or_return(
        :usage_mode,
        arg,
        kind_of: String,
        equal_to: %w{ exclusive normal }
      )
    end

    #
    # The list of labels for this slave.
    #
    # @param [String, Array<String>] arg
    # @return [Array<String>]
    #
    def labels(arg = nil)
      if arg.nil?
        @labels
      else
        @labels += Array(arg).compact.map(&:to_s)
      end
    end

    #
    # Controls when Jenkins starts and stops a slave.
    #
    # @param [String] arg
    # @option arg [String] `always` Keep this slave on-line as much as possible.
    # @option arg [String] `demand` Take this slave on-line when in demand and off-line when idle.
    # @return [String]
    #
    def availability(arg = nil)
      set_or_return(
        :availability,
        arg,
        kind_of: String,
        equal_to: %w{ always demand }
      )
    end

    #
    # The number of minutes for which jobs must be waiting in the queue
    # before attempting to launch this slave. This value is only used
    # when `availability` is set to `demand`.
    #
    # @param [Integer] arg
    # @return [Integer]
    #
    def in_demand_delay(arg = nil)
      set_or_return(:in_demand_delay, arg, kind_of: Integer)
    end

    #
    # The number of minutes that this slave must remain idle before
    # taking it off-line. This value is only used when `availability` is
    # set to `demand`.
    #
    # @param [Integer] arg
    # @return [Integer]
    #
    def idle_delay(arg = nil)
      set_or_return(:idle_delay, arg, kind_of: Integer)
    end

    #
    # A Hash of environment variables which are set directly on the
    # slaves configuration. These key-value pairs apply for every build
    # on this slave and override any global values. They can be used in
    # Jenkins' configuration (as $key or ${key}) and be will added to
    # the environment for processes launched from the build.
    #
    # @param [Hash] arg
    # @return [Hash]
    #
    # @example Ruby 1.9+ style Hash
    #   {ENV_VARIABLE: 'VALUE'}
    # @example Ruby 1.8 style Hash
    #   {'ENV_VARIABLE' => 'VALUE'}
    #
    def environment(arg=nil)
      set_or_return(:environment, arg, kind_of: Hash)
    end

    #
    # The reason a node is going offline.
    #
    # @param [String] arg
    # @return [String]
    #
    def offline_reason(arg = nil)
      set_or_return(:offline_reason, arg, kind_of: String)
    end

    #
    # Determine if the slave exists on the master. This value is set by
    # the provider when the current resource is loaded.
    #
    # @return [Boolean]
    #
    def exists?
      !!@exists
    end

    #
    # Determine if the slave is connected to the master. This value is
    # set by the provider when the current resource is loaded.
    #
    # @return [Boolean]
    #
    def connected?
      !!@connected
    end

    #
    # Determine if the slave is online. This value is set by the
    # provider when the current resource is loaded.
    #
    # @return [Boolean]
    #
    def online?
      !!@online
    end
  end
end

#
#
#
class Chef
  class Provider::JenkinsSlave < Provider
    require 'json'

    include Jenkins::Helper

    #
    # This provider supports why-run mode.
    #
    def whyrun_supported?
      true
    end

    def load_current_resource
      @current_resource ||= Resource::JenkinsSlave.new(new_resource.name)

      set_base_attributes
    end

    #
    # Create the given slave.
    #
    def action_create
      if current_resource.exists? && has_correct_config?
        Chef::Log.debug("#{new_resource} exists - skipping")
      else
        converge_by("Create #{new_resource}") do
          executor.groovy! <<-EOH.gsub(/ ^{12}/, '')
            import hudson.model.*
            import hudson.slaves.*
            import jenkins.model.*
            import jenkins.slaves.*

            props = []
            availability = #{convert_to_groovy(new_resource.availability)}
            usage_mode = #{convert_to_groovy(new_resource.usage_mode)}
            env_map = #{convert_to_groovy(new_resource.environment)}
            labels = #{convert_to_groovy((auto_labels + new_resource.labels).sort.join("\s"))}

            // Compute the usage mode
            if (usage_mode == 'normal') {
              mode = Node.Mode.NORMAL
            } else {
              mode = Node.Mode.EXCLUSIVE
            }

            // Compute the retention strategy
            if (availability == 'demand') {
              retention_strategy = new RetentionStrategy.Demand(#{new_resource.in_demand_delay},
                                                                #{new_resource.idle_delay})
            } else if (availability == 'always') {
              retention_strategy = new RetentionStrategy.Always()
            } else {
              retention_strategy = RetentionStrategy.NOOP
            }

            // Create an entry in the prop list for all env vars
            if (env_map != null) {
              env_vars = new hudson.EnvVars(env_map)
              entries = env_vars.collect { k,v -> new EnvironmentVariablesNodeProperty.Entry(k,v) }
              props << new EnvironmentVariablesNodeProperty(entries)
            }

            // Launcher
            #{launcher_groovy}

            // Build the slave object
            slave = new DumbSlave(#{convert_to_groovy(new_resource.name)},
                                  #{convert_to_groovy(new_resource.description)},
                                  #{convert_to_groovy(new_resource.remote_fs)},
                                  #{convert_to_groovy(new_resource.executors.to_s)},
                                  mode,
                                  labels,
                                  launcher,
                                  retention_strategy,
                                  props)

            // Create or update the slave in the Jenkins instance
            nodes = new ArrayList(Jenkins.instance.getNodes())
            ix = nodes.indexOf(slave)
            (ix >= 0) ? nodes.set(ix, slave) : nodes.add(slave)
            Jenkins.instance.setNodes(nodes)
          EOH
        end
      end
    end

    #
    # Delete the given slave.
    #
    def action_delete
      if current_resource.exists?
        converge_by("Delete #{new_resource}") do
          executor.execute!("delete-node", new_resource.name)
        end
      else
        Chef::Log.debug("#{new_resource} does not exist - skipping")
      end
    end

    #
    # Connect the given slave.
    #
    def action_connect
      if current_resource.exists? && current_resource.connected?
        Chef::Log.debug("#{new_resource} connected - skipping")
      else
        converge_by("Connect #{new_resource}") do
          executor.execute!("connect-node", new_resource.name)
        end
      end
    end

    #
    # Connect the given slave.
    #
    def action_disconnect
      if current_resource.connected?
        converge_by("Disconnect #{new_resource}") do
          executor.execute!("disconnect-node", new_resource.name)
        end
      else
        Chef::Log.debug("#{new_resource} not connected - skipping")
      end
    end

    #
    # Take the given slave online.
    #
    def action_online
      if current_resource.exists? && current_resource.online?
        Chef::Log.debug("#{new_resource} online - skipping")
      else
        converge_by("Online #{new_resource}") do
          executor.execute!("online-node", new_resource.name)
        end
      end
    end

    #
    # Take the given slave offline.
    #
    def action_offline
      if current_resource.online?
        converge_by("Offline #{new_resource}") do
          command_pieces  = [new_resource.name]
          command_pieces << "-m '#{new_resource.offline_reason}'" if new_resource.offline_reason
          executor.execute!("offline-node", command_pieces)
        end
      else
        Chef::Log.debug("#{new_resource} offline - skipping")
      end
    end

    protected

    #
    # Helper method for setting base attributes on current_slave
    # instance. This should be called from a descendant's
    # `#load_current_resource` method.
    #
    def set_base_attributes
      if current_slave
        @current_resource.exists    = true
        @current_resource.connected = current_slave[:connected]
        @current_resource.online    = current_slave[:online]

        @current_resource.description(current_slave[:description])
        @current_resource.remote_fs(current_slave[:remote_fs])
        @current_resource.executors(current_slave[:executors])
        @current_resource.labels(current_slave[:labels])
      end
    end

    #
    # Returns a Groovy snippet that creates an instance of the slave's
    # launcher implementation. The launcher instance should be set to
    # a Groovy variable named `launcher`.
    #
    # @abstract
    # @return [String]
    #
    def launcher_groovy
      raise NotImplementedError, 'You must implement #launcher_groovy.'
    end

    #
    # Maps a slave's resource attribute name to the equivalent property
    # in the Groovy representation. This mapping is useful in
    # Ruby/Groovy serialization/deserialization.
    #
    # @return [Hash]
    #
    # @example
    #   {host: 'host',
    #    port: 'port',
    #    credential_username: 'username',
    #    jvm_options: 'jvmOptions'}
    #
    def attribute_to_property_map
      {}
    end

    private

    #
    # Loads the current slave into a Hash.
    #
    def current_slave
      return @current_slave if @current_slave

      Chef::Log.debug "Load #{new_resource} slave information"

      launcher_attributes = []
      attribute_to_property_map.each_pair do |resource_attribute, groovy_property|
        launcher_attributes << "current_slave['#{resource_attribute}'] = #{groovy_property}"
      end

      json = executor.groovy! <<-EOH.gsub(/ ^{8}/, '')
        import hudson.model.*
        import hudson.slaves.*
        import jenkins.model.*
        import jenkins.slaves.*

        slave = Jenkins.instance.getNode('#{new_resource.name}') as Slave

        if(slave == null) {
          return null
        }

        current_slave = [
          name:slave.name,
          description:slave.nodeDescription,
          remote_fs:slave.remoteFS,
          executors:slave.numExecutors.toInteger(),
          usage_mode:slave.mode.toString().toLowerCase(),
          labels:slave.labelString.split().sort(),
          environment:slave.nodeProperties.get(EnvironmentVariablesNodeProperty.class)?.envVars,
          connected:(slave.computer.connectTime > 0),
          online:slave.computer.online
        ]

        // Determine retention strategy
        if (slave.retentionStrategy instanceof RetentionStrategy.Always) {
          current_slave['availability'] = 'always'
        } else if (slave.retentionStrategy instanceof RetentionStrategy.Demand) {
          current_slave['availability'] = 'demand'
          retention = slave.retentionStrategy as RetentionStrategy.Demand
          current_slave['in_demand_delay'] = retention.inDemandDelay
          current_slave['idle_delay'] = retention.idleDelay
        } else {
          current_slave['availability'] = null
        }

        #{launcher_attributes.join("\n")}

        builder = new groovy.json.JsonBuilder(current_slave)
        println(builder)
      EOH

      return nil if json.nil? || json.empty?

      @current_slave = JSON.parse(json, symbolize_names: true)

      # Values that were serialized as nil/null are deserialized as an
      # empty string! :( Let's ensure we convert back to nil.
      @current_slave = convert_blank_values_to_nil(@current_slave)
    end

    #
    # Helper method for determining if the given JSON is in sync with the
    # current configuration on the Jenkins server.
    #
    # @return [Boolean]
    #
    def has_correct_config?
      wanted_slave = {
        name: new_resource.name,
        description: new_resource.description,
        remote_fs: new_resource.remote_fs,
        executors: new_resource.executors,
        usage_mode: new_resource.usage_mode,
        labels: (auto_labels + new_resource.labels).sort,
        availability: new_resource.availability,
        environment: new_resource.environment
      }

      if new_resource.availability.to_s == 'demand'
        wanted_slave[:in_demand_delay] = new_resource.in_demand_delay
        wanted_slave[:idle_delay] = new_resource.idle_delay
      end

      attribute_to_property_map.keys.each do |key|
        wanted_slave[key] = new_resource.send(key)
      end

      # Don't include connected/online values in the comparison
      current_slave.dup.tap do |c|
        c.delete(:connected)
        c.delete(:online)
      end == wanted_slave
    end

    #
    # Generates a set of useful labels based on the current `node`
    # object.
    #
    # @return [Array<String>]
    #
    def auto_labels
      return @auto_labels if @auto_labels

      @auto_labels  = []
      @auto_labels << node['platform'] # ubuntu
      @auto_labels << node['platform_family'] # debian
      @auto_labels << node['platform_version'] # 10.04
      @auto_labels << [ node['platform'], node['platform_version']].join('-') # ubuntu-10.04
      @auto_labels << node['kernel']['machine'] # x86_64
      @auto_labels << node['os'] # linux
      @auto_labels << node['os_version'] # 2.6.32-38-server
      @auto_labels << node['virtualization']['system'] if node.attribute?('virtualization') # xen
      @auto_labels += node['tags']
      @auto_labels.flatten.sort
    end
  end
end
