#
# Cookbook:: jenkins
# Resource:: slave
#
# Author:: Seth Chisamore <schisamo@chef.io>
#
# Copyright:: 2013-2019, Chef Software, Inc.
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

require 'json'

require_relative '_helper'

class Chef
  class Resource::JenkinsSlave < Resource::LWRPBase
    resource_name :jenkins_slave # Still needed for Chef 15 and below
    provides :jenkins_slave

    # Chef attributes
    identity_attr :slave_name

    # Actions
    actions :create, :delete, :connect, :disconnect, :online, :offline
    default_action :create

    # Attributes
    attribute :slave_name,
              kind_of: String,
              name_attribute: true
    attribute :description,
              kind_of: String,
              default: lazy { |new_resource| "Jenkins slave #{new_resource.slave_name}" }
    attribute :remote_fs,
              kind_of: String,
              default: '/home/jenkins'
    attribute :executors,
              kind_of: Integer,
              default: 1
    attribute :usage_mode,
              kind_of: String,
              equal_to: %w(exclusive normal),
              default: 'normal'
    attribute :labels,
              kind_of: Array,
              default: []
    attribute :availability,
              kind_of: String,
              equal_to: %w(always demand)
    attribute :in_demand_delay,
              kind_of: Integer,
              default: 0
    attribute :idle_delay,
              kind_of: Integer,
              default: 1
    attribute :environment,
              kind_of: Hash
    attribute :offline_reason,
              kind_of: String
    attribute :user,
              kind_of: String,
              regex: Config[:user_valid_regex],
              default: 'jenkins'
    attribute :jvm_options,
              kind_of: String
    attribute :java_path,
              kind_of: String

    attr_writer :exists
    attr_writer :connected
    attr_writer :online

    #
    # Determine if the slave exists on the master. This value is set by
    # the provider when the current resource is loaded.
    #
    # @return [Boolean]
    #
    def exists?
      !@exists.nil? && @exists
    end

    #
    # Determine if the slave is connected to the master. This value is
    # set by the provider when the current resource is loaded.
    #
    # @return [Boolean]
    #
    def connected?
      !@connected.nil? && @connected
    end

    #
    # Determine if the slave is online. This value is set by the
    # provider when the current resource is loaded.
    #
    # @return [Boolean]
    #
    def online?
      !@online.nil? && @online
    end
  end
end

class Chef
  class Provider::JenkinsSlave < Provider::LWRPBase
    provides :jenkins_slave

    include Jenkins::Helper

    provides :jenkins_slave

    def load_current_resource
      @current_resource ||= Resource::JenkinsSlave.new(new_resource.name)

      if current_slave
        @current_resource.exists     = true
        @current_resource.connected  = current_slave[:connected]
        @current_resource.online     = current_slave[:online]

        @current_resource.slave_name(new_resource.slave_name)
        @current_resource.description(current_slave[:description])
        @current_resource.remote_fs(current_slave[:remote_fs])
        @current_resource.executors(current_slave[:executors])
        @current_resource.labels(current_slave[:labels])
      end

      @current_resource
    end

    action :create do
      do_create
    end

    def merge_preserved_labels!
      new_resource.labels |= current_resource.labels.select { |i| i[/^prsrv_/] }
    end

    def do_create
      # Preserve some labels...
      merge_preserved_labels!
      if current_resource.exists? && correct_config?
        Chef::Log.info("#{new_resource} exists - skipping")
      else
        converge_by("Create #{new_resource}") do
          executor.groovy! <<-EOH.gsub(/^ {12}/, '')
            import hudson.model.*
            import hudson.slaves.*
            import jenkins.model.*
            import jenkins.slaves.*

            props = []
            availability = #{convert_to_groovy(new_resource.availability)}
            usage_mode = #{convert_to_groovy(new_resource.usage_mode)}
            env_map = #{convert_to_groovy(new_resource.environment)}
            labels = #{convert_to_groovy(new_resource.labels.sort.join(' '))}

            // Compute the usage mode
            if (usage_mode == 'normal') {
              mode = Node.Mode.NORMAL
            } else {
              mode = Node.Mode.EXCLUSIVE
            }

            // Compute the retention strategy
            if (availability == 'demand') {
              retention_strategy =
                new RetentionStrategy.Demand(
                  #{new_resource.in_demand_delay},
                  #{new_resource.idle_delay}
              )
            } else if (availability == 'always') {
              retention_strategy = new RetentionStrategy.Always()
            } else {
              retention_strategy = RetentionStrategy.NOOP
            }

            // Create an entry in the prop list for all env vars
            if (env_map != null) {
              env_vars = new hudson.EnvVars(env_map)
              entries = env_vars.collect {
                k,v -> new EnvironmentVariablesNodeProperty.Entry(k,v)
              }
              props << new EnvironmentVariablesNodeProperty(entries)
            }

            // Launcher
            #{launcher_groovy}

            // Build the slave object
            slave = new DumbSlave(
              #{convert_to_groovy(new_resource.name)},
              #{convert_to_groovy(new_resource.description)},
              #{convert_to_groovy(new_resource.remote_fs)},
              #{convert_to_groovy(new_resource.executors.to_s)},
              mode,
              labels,
              launcher,
              retention_strategy,
              props
            )

            // Create or update the slave in the Jenkins instance
            nodes = new ArrayList(Jenkins.instance.getNodes())
            ix = nodes.indexOf(slave)
            (ix >= 0) ? nodes.set(ix, slave) : nodes.add(slave)
            Jenkins.instance.setNodes(nodes)
          EOH
        end
      end
    end

    action :delete do
      do_delete
    end

    def do_delete
      if current_resource.exists?
        converge_by("Delete #{new_resource}") do
          executor.execute!('delete-node', escape(new_resource.slave_name))
        end
      else
        Chef::Log.debug("#{new_resource} does not exist - skipping")
      end
    end

    action :connect do
      if current_resource.exists? && current_resource.connected?
        Chef::Log.debug("#{new_resource} already connected - skipping")
      else
        converge_by("Connect #{new_resource}") do
          executor.execute!('connect-node', escape(new_resource.slave_name))
        end
      end
    end

    action :disconnect do
      if current_resource.connected?
        converge_by("Disconnect #{new_resource}") do
          executor.execute!('disconnect-node', escape(new_resource.slave_name))
        end
      else
        Chef::Log.debug("#{new_resource} already disconnected - skipping")
      end
    end

    action :online do
      if current_resource.exists? && current_resource.online?
        Chef::Log.debug("#{new_resource} already online - skipping")
      else
        converge_by("Online #{new_resource}") do
          executor.execute!('online-node', escape(new_resource.slave_name))
        end
      end
    end

    action :offline do
      if current_resource.online?
        converge_by("Offline #{new_resource}") do
          command_pieces = [escape(new_resource.slave_name)]
          command_pieces << "-m '#{escape(new_resource.offline_reason)}'" if new_resource.offline_reason
          executor.execute!('offline-node', command_pieces)
        end
      else
        Chef::Log.debug("#{new_resource} already offline - skipping")
      end
    end

    private

    #
    # Returns a Groovy snippet that creates an instance of the slave's
    # launcher implementation. The launcher instance should be set to
    # a Groovy variable named `launcher`.
    #
    # @return [String]
    #
    def launcher_groovy
      'launcher = new hudson.slaves.JNLPLauncher()'
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

      json = executor.groovy! <<-EOH.gsub(/^ {8}/, '')
        import hudson.model.*
        import hudson.slaves.*
        import jenkins.model.*
        import jenkins.slaves.*

        slave = Jenkins.instance.getNode('#{new_resource.slave_name}') as Slave

        if(slave == null) {
          return null
        }

        def slave_environment = null
        slave_env_vars = slave.nodeProperties.get(EnvironmentVariablesNodeProperty.class)?.envVars
        if (slave_env_vars)
          slave_environment = new java.util.HashMap<String,String>(slave_env_vars)

        current_slave = [
          name:slave.name,
          description:slave.nodeDescription,
          remote_fs:slave.remoteFS,
          executors:slave.numExecutors.toInteger(),
          usage_mode:slave.mode.toString().toLowerCase(),
          labels:slave.labelString.split().sort(),
          environment:slave_environment,
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
    # current configuration on the Jenkins master.
    #
    # @return [Boolean]
    #
    def correct_config?
      wanted_slave = {
        name: new_resource.slave_name,
        description: new_resource.description,
        remote_fs: new_resource.remote_fs,
        executors: new_resource.executors,
        usage_mode: new_resource.usage_mode,
        labels: new_resource.labels.sort,
        availability: new_resource.availability,
        environment: new_resource.environment,
      }

      if new_resource.availability.to_s == 'demand'
        wanted_slave[:in_demand_delay] = new_resource.in_demand_delay
        wanted_slave[:idle_delay] = new_resource.idle_delay
      end

      attribute_to_property_map.each_key do |key|
        wanted_slave[key] = new_resource.send(key)
      end

      # Don't include connected/online values in the comparison
      current_slave.dup.tap do |c|
        c.delete(:connected)
        c.delete(:online)
      end == wanted_slave
    end
  end
end
