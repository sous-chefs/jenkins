unified_mode true

resource_name :jenkins_executor_config
provides :jenkins_executor_config

default_action :configure

property :endpoint, String
property :home, String
property :proxy, String
property :timeout, Integer
property :java, String
property :jvm_options, String
property :protocol, String, equal_to: %w(http ssh remoting)
property :cli_user, String
property :cli_username, String
property :cli_password, String, sensitive: true
property :cli_credential_file, String
property :update_center_mirror, String
property :update_center_channel, String
property :update_center_sleep, Integer
property :user, String
property :group, String

action :configure do
  persist_runtime_configuration
end

action :create do
  persist_runtime_configuration
end

action_class do
  def persist_runtime_configuration
    runtime_updates = {
      endpoint: new_resource.endpoint,
      home: new_resource.home,
      proxy: new_resource.proxy,
      timeout: new_resource.timeout,
      java: new_resource.java,
      jvm_options: new_resource.jvm_options,
      protocol: new_resource.protocol,
      cli_user: new_resource.cli_user,
      cli_username: new_resource.cli_username,
      cli_password: new_resource.cli_password,
      cli_credential_file: new_resource.cli_credential_file,
      update_center_mirror: new_resource.update_center_mirror,
      update_center_channel: new_resource.update_center_channel,
      update_center_sleep: new_resource.update_center_sleep,
      user: new_resource.user,
      group: new_resource.group,
    }.compact

    converge_by('Configure Jenkins executor runtime settings') do
      node.run_state[:jenkins_runtime_config] ||= {}
      node.run_state[:jenkins_runtime_config].merge!(runtime_updates)
      node.run_state[:jenkins_runtime_config]
    end
  end
end
