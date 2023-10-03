require 'json'

unified_mode true

property :slave.name,
          String,
          name_property: true
property :description,
          String,
          default: lazy { |new_resource| "Jenkins slave #{new_resource.slave.name}" }
property :remote_fs,
          String,
          default: '/home/jenkins'
property :executors,
          Integer,
          default: 1
property :usage_mode,
          String,
          equal_to: %w(exclusive normal),
          default: 'normal'
property :labels,
          Array,
          default: []
property :availability,
          String,
          equal_to: %w(always demand)
property :in_demand_delay,
          Integer,
          default: 0
property :idle_delay,
          Integer,
          default: 1
property :environment,
          Hash
property :offline_reason,
          String
property :user,
          String,
          regex: Config[:user_valid_regex],
          default: 'jenkins'
property :jvm_options,
          String
property :java_path,
          String

include Jenkins::Cookbook::Slave
include Jenkins::Helper

def load_current_resource
  @current_resource ||= Resource::JenkinsSlave.new(new_resource.name)

  if current_slave
    @current_resource.exists     = true
    @current_resource.connected  = current_slave[:connected]
    @current_resource.online     = current_slave[:online]

    @current_resource.slave.name(new_resource.slave.name)
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

action :delete do
  do_delete
end

def do_delete
  if current_resource.exists?
    converge_by("Delete #{new_resource}") do
      executor.execute!('delete-node', escape(new_resource.slave.name))
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
      executor.execute!('connect-node', escape(new_resource.slave.name))
    end
  end
end

action :disconnect do
  if current_resource.connected?
    converge_by("Disconnect #{new_resource}") do
      executor.execute!('disconnect-node', escape(new_resource.slave.name))
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
      executor.execute!('online-node', escape(new_resource.slave.name))
    end
  end
end

action :offline do
  if current_resource.online?
    converge_by("Offline #{new_resource}") do
      command_pieces = [escape(new_resource.slave.name)]
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
# Maps a slave's resource property name to the equivalent property
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
def property_to_property_map
  {}
end

#
# Loads the current slave into a Hash.
#
def current_slave
  return @current_slave if @current_slave

  Chef::Log.debug "Load #{new_resource} slave information"

  launcher_propertys = []
  property_to_property_map.each_pair do |resource_property, groovy_property|
    launcher_propertys << "current_slave['#{resource_property}'] = #{groovy_property}"
  end

  json = executor.groovy! <<-EOH.gsub(/^ {8}/, '')
    import hudson.model.*
    import hudson.slaves.*
    import jenkins.model.*
    import jenkins.slaves.*

    slave = Jenkins.instance.getNode('#{new_resource.slave.name}') as Slave

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

    #{launcher_propertys.join("\n")}

    builder = new groovy.json.JsonBuilder(current_slave)
    println(builder)
  EOH

  return if json.nil? || json.empty?

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
    name: new_resource.slave.name,
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

  property_to_property_map.each_key do |key|
    wanted_slave[key] = new_resource.send(key)
  end

  # Don't include connected/online values in the comparison
  current_slave.dup.tap do |c|
    c.delete(:connected)
    c.delete(:online)
  end == wanted_slave
end
