unified_mode true

resource_name :jenkins_executor_config
provides :jenkins_executor_config

default_action :configure

property :endpoint, String
property :proxy, String
property :disable_security, [true, false]

action :configure do
  converge_by('Configure Jenkins executor runtime settings') do
    node.run_state[:jenkins_runtime_config] ||= {}

    node.run_state[:jenkins_runtime_config][:endpoint] = new_resource.endpoint unless new_resource.endpoint.nil?
    node.run_state[:jenkins_runtime_config][:proxy] = new_resource.proxy unless new_resource.proxy.nil?
    node.run_state[:jenkins_runtime_config][:disable_security] = new_resource.disable_security unless new_resource.disable_security.nil?
  end
end

action :create do
  converge_by('Configure Jenkins executor runtime settings') do
    node.run_state[:jenkins_runtime_config] ||= {}

    node.run_state[:jenkins_runtime_config][:endpoint] = new_resource.endpoint unless new_resource.endpoint.nil?
    node.run_state[:jenkins_runtime_config][:proxy] = new_resource.proxy unless new_resource.proxy.nil?
    node.run_state[:jenkins_runtime_config][:disable_security] = new_resource.disable_security unless new_resource.disable_security.nil?
  end
end
