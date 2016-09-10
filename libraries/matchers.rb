if defined?(ChefSpec)
  ChefSpec.define_matcher :jenkins_command
  def execute_jenkins_command(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(
      :jenkins_command,
      :execute,
      resource_name)
  end

  ChefSpec.define_matcher :jenkins_credentials
  def create_jenkins_credentials(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(
      :jenkins_credentials,
      :create,
      resource_name)
  end

  def delete_jenkins_credentials(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(
      :jenkins_credentials,
      :delete,
      resource_name)
  end

  ChefSpec.define_matcher :jenkins_password_credentials
  def create_jenkins_password_credentials(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(
      :jenkins_password_credentials,
      :create,
      resource_name)
  end

  def delete_jenkins_password_credentials(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(
      :jenkins_password_credentials,
      :delete,
      resource_name)
  end

  ChefSpec.define_matcher :jenkins_private_key_credentials
  def create_jenkins_private_key_credentials(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(
      :jenkins_private_key_credentials,
      :create,
      resource_name)
  end

  def delete_jenkins_private_key_credentials(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(
      :jenkins_private_key_credentials,
      :delete,
      resource_name)
  end

  ChefSpec.define_matcher :jenkins_secret_text_credentials
  def create_jenkins_secret_text_credentials(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(
      :jenkins_secret_text_credentials,
      :create,
      resource_name)
  end

  def delete_jenkins_secret_text_credentials(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(
      :jenkins_secret_text_credentials,
      :delete,
      resource_name)
  end

  ChefSpec.define_matcher :jenkins_job
  def build_jenkins_job(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(
      :jenkins_job,
      :build,
      resource_name)
  end

  def create_jenkins_job(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(
      :jenkins_job,
      :create,
      resource_name)
  end

  def delete_jenkins_job(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(
      :jenkins_job,
      :delete,
      resource_name)
  end

  def disable_jenkins_job(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(
      :jenkins_job,
      :disable,
      resource_name)
  end

  def enable_jenkins_job(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(
      :jenkins_job,
      :enable,
      resource_name)
  end

  ChefSpec.define_matcher :jenkins_plugin
  def install_jenkins_plugin(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(
      :jenkins_plugin,
      :install,
      resource_name)
  end

  def uninstall_jenkins_plugin(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(
      :jenkins_plugin,
      :uninstall,
      resource_name)
  end

  def enable_jenkins_plugin(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(
      :jenkins_plugin,
      :enable,
      resource_name)
  end

  def disable_jenkins_plugin(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(
      :jenkins_plugin,
      :disable,
      resource_name)
  end

  ChefSpec.define_matcher :jenkins_script
  def execute_jenkins_script(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(
      :jenkins_script,
      :execute,
      resource_name)
  end

  ChefSpec.define_matcher :jenkins_slave
  def create_jenkins_slave(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(
      :jenkins_slave,
      :create,
      resource_name)
  end

  def delete_jenkins_slave(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(
      :jenkins_slave,
      :delete,
      resource_name)
  end

  def connect_jenkins_slave(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(
      :jenkins_slave,
      :connect,
      resource_name)
  end

  def disconnect_jenkins_slave(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(
      :jenkins_slave,
      :disconnect,
      resource_name)
  end

  def online_jenkins_slave(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(
      :jenkins_slave,
      :online,
      resource_name)
  end

  def offline_jenkins_slave(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(
      :jenkins_slave,
      :offline,
      resource_name)
  end

  ChefSpec.define_matcher :jenkins_jnlp_slave
  def create_jenkins_jnlp_slave(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(
      :jenkins_jnlp_slave,
      :create,
      resource_name)
  end

  def delete_jenkins_jnlp_slave(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(
      :jenkins_jnlp_slave,
      :delete,
      resource_name)
  end

  def connect_jenkins_jnlp_slave(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(
      :jenkins_jnlp_slave,
      :connect,
      resource_name)
  end

  def disconnect_jenkins_jnlp_slave(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(
      :jenkins_jnlp_slave,
      :disconnect,
      resource_name)
  end

  def online_jenkins_jnlp_slave(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(
      :jenkins_jnlp_slave,
      :online,
      resource_name)
  end

  def offline_jenkins_jnlp_slave(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(
      :jenkins_jnlp_slave,
      :offline,
      resource_name)
  end

  ChefSpec.define_matcher :jenkins_ssh_slave
  def create_jenkins_ssh_slave(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(
      :jenkins_ssh_slave,
      :create,
      resource_name)
  end

  def delete_jenkins_ssh_slave(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(
      :jenkins_ssh_slave,
      :delete,
      resource_name)
  end

  def connect_jenkins_ssh_slave(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(
      :jenkins_ssh_slave,
      :connect,
      resource_name)
  end

  def disconnect_jenkins_ssh_slave(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(
      :jenkins_ssh_slave,
      :disconnect,
      resource_name)
  end

  def online_jenkins_ssh_slave(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(
      :jenkins_ssh_slave,
      :online,
      resource_name)
  end

  def offline_jenkins_ssh_slave(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(
      :jenkins_ssh_slave,
      :offline,
      resource_name)
  end

  ChefSpec.define_matcher :jenkins_windows_slave
  def create_jenkins_windows_slave(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(
      :jenkins_windows_slave,
      :create,
      resource_name)
  end

  def delete_jenkins_windows_slave(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(
      :jenkins_windows_slave,
      :delete,
      resource_name)
  end

  def connect_jenkins_windows_slave(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(
      :jenkins_windows_slave,
      :connect,
      resource_name)
  end

  def disconnect_jenkins_windows_slave(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(
      :jenkins_windows_slave,
      :disconnect,
      resource_name)
  end

  def online_jenkins_windows_slave(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(
      :jenkins_windows_slave,
      :online,
      resource_name)
  end

  def offline_jenkins_windows_slave(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(
      :jenkins_windows_slave,
      :offline,
      resource_name)
  end

  ChefSpec.define_matcher :jenkins_user
  def create_jenkins_user(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(
      :jenkins_user,
      :create,
      resource_name)
  end

  def delete_jenkins_user(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(
      :jenkins_user,
      :delete,
      resource_name)
  end
end
