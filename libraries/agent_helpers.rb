#
# Cookbook:: jenkins
# Library:: agent_helpers
#

require_relative '_helper'

module Jenkins
  module AgentHelpers
    include Jenkins::Helper

    def attribute_to_property_map
      {}
    end

    def current_slave_from_jenkins(resource = agent_resource)
      return @current_slave if @current_slave

      Chef::Log.debug "Load #{resource} agent information"

      launcher_attributes = []
      attribute_to_property_map.each_pair do |resource_attribute, groovy_property|
        launcher_attributes << "current_slave['#{resource_attribute}'] = #{groovy_property}"
      end

      json = executor.groovy! <<-EOH.gsub(/^ {6}/, '')
        import hudson.model.*
        import hudson.slaves.*
        import jenkins.model.*
        import jenkins.slaves.*

        slave = Jenkins.instance.getNode('#{resource.slave_name}') as Slave

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

        #{launcher_attributes.join("\n")}

        builder = new groovy.json.JsonBuilder(current_slave)
        println(builder)
      EOH

      return if json.nil? || json.empty?

      @current_slave = JSON.parse(json, symbolize_names: true)
      @current_slave = convert_blank_values_to_nil(@current_slave)
    end

    private

    def agent_resource
      respond_to?(:new_resource) && new_resource ? new_resource : self
    end
  end
end
