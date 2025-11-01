require 'json'

unified_mode true

resource_name :jenkins_windows_slave
provides :jenkins_windows_slave

# Inherit properties from base agent resource
property :slave_name, String, name_property: true
property :description, String,
         default: lazy { |r| "Jenkins agent #{r.slave_name}" }
property :remote_fs, String, default: 'C:\\Jenkins'
property :executors, Integer, default: 1
property :usage_mode, String, equal_to: %w(exclusive normal), default: 'normal'
property :labels, Array, default: []
property :availability, String, equal_to: %w(always demand)
property :in_demand_delay, Integer, default: 0
property :idle_delay, Integer, default: 1
property :environment, Hash
property :offline_reason, String
property :user, String, default: 'Administrator'
property :jvm_options, String
property :java_path, String

# Windows-specific properties
property :password, String, sensitive: true

load_current_value do
  current_slave_data = current_slave_from_jenkins

  if current_slave_data
    slave_name current_slave_data[:name]
    description current_slave_data[:description]
    remote_fs current_slave_data[:remote_fs]
    executors current_slave_data[:executors]
    labels current_slave_data[:labels]

    @exists = true
    @connected = current_slave_data[:connected]
    @online = current_slave_data[:online]
  else
    current_value_does_not_exist!
  end
end

action :create do
  do_create
  # NOTE: Windows-specific service management would go here
end

action :delete do
  do_delete
end

action :connect do
  if current_resource && connected?
    Chef::Log.debug("#{new_resource} already connected - skipping")
  else
    converge_by("Connect #{new_resource}") do
      executor.execute!('connect-node', escape(new_resource.slave_name))
    end
  end
end

action :disconnect do
  if connected?
    converge_by("Disconnect #{new_resource}") do
      executor.execute!('disconnect-node', escape(new_resource.slave_name))
    end
  else
    Chef::Log.debug("#{new_resource} already disconnected - skipping")
  end
end

action :online do
  if current_resource && online?
    Chef::Log.debug("#{new_resource} already online - skipping")
  else
    converge_by("Online #{new_resource}") do
      executor.execute!('online-node', escape(new_resource.slave_name))
    end
  end
end

action :offline do
  if online?
    converge_by("Offline #{new_resource}") do
      command_pieces = [escape(new_resource.slave_name)]
      command_pieces << "-m '#{escape(new_resource.offline_reason)}'" if new_resource.offline_reason
      executor.execute!('offline-node', command_pieces)
    end
  else
    Chef::Log.debug("#{new_resource} already offline - skipping")
  end
end

action_class do
  include Jenkins::Helper

  def exists?
    !@exists.nil? && @exists
  end

  def connected?
    !@connected.nil? && @connected
  end

  def online?
    !@online.nil? && @online
  end

  def merge_preserved_labels!
    if current_resource
      new_resource.labels |= current_resource.labels.select { |i| i[/^prsrv_/] }
    end
  end

  def do_create
    merge_preserved_labels!
    if current_resource && correct_config?
      Chef::Log.info("#{new_resource} exists - skipping")
    else
      converge_by("Create #{new_resource}") do
        executor.groovy! <<-EOH.gsub(/^ {10}/, '')
          import hudson.model.*
          import hudson.slaves.*
          import jenkins.model.*
          import jenkins.slaves.*

          props = []
          availability = #{convert_to_groovy(new_resource.availability)}
          usage_mode = #{convert_to_groovy(new_resource.usage_mode)}
          env_map = #{convert_to_groovy(new_resource.environment)}
          labels = #{convert_to_groovy(new_resource.labels.sort.join(' '))}

          if (usage_mode == 'normal') {
            mode = Node.Mode.NORMAL
          } else {
            mode = Node.Mode.EXCLUSIVE
          }

          if (availability == 'demand') {
            retention_strategy = new RetentionStrategy.Demand(
              #{new_resource.in_demand_delay},
              #{new_resource.idle_delay}
            )
          } else if (availability == 'always') {
            retention_strategy = new RetentionStrategy.Always()
          } else {
            retention_strategy = RetentionStrategy.NOOP
          }

          if (env_map != null) {
            env_vars = new hudson.EnvVars(env_map)
            entries = env_vars.collect {
              k,v -> new EnvironmentVariablesNodeProperty.Entry(k,v)
            }
            props << new EnvironmentVariablesNodeProperty(entries)
          }

          launcher = new hudson.slaves.JNLPLauncher()

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

          nodes = new ArrayList(Jenkins.instance.getNodes())
          ix = nodes.indexOf(slave)
          (ix >= 0) ? nodes.set(ix, slave) : nodes.add(slave)
          Jenkins.instance.setNodes(nodes)
        EOH
      end
    end
  end

  def do_delete
    if current_resource
      converge_by("Delete #{new_resource}") do
        executor.execute!('delete-node', escape(new_resource.slave_name))
      end
    else
      Chef::Log.debug("#{new_resource} does not exist - skipping")
    end
  end

  def current_slave_from_jenkins
    return @current_slave if @current_slave

    Chef::Log.debug "Load #{new_resource} agent information"

    json = executor.groovy! <<-EOH.gsub(/^ {6}/, '')
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

      builder = new groovy.json.JsonBuilder(current_slave)
      println(builder)
    EOH

    return if json.nil? || json.empty?

    @current_slave = JSON.parse(json, symbolize_names: true)
    @current_slave = convert_blank_values_to_nil(@current_slave)
  end

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

    current_slave_from_jenkins.dup.tap do |c|
      c.delete(:connected)
      c.delete(:online)
    end == wanted_slave
  end
end
