unified_mode true
use 'partials/slave'
use 'partials/credentials'

property :host,
          String
property :port,
          Integer,
          default: 22
property :credentials,
         String
          # [String, Resource::JenkinsCredentials]
property :command_prefix,
          String
property :command_suffix,
          String
property :launch_timeout,
          Integer
property :ssh_retries,
          Integer
property :ssh_wait_retries,
          Integer

#
# The credentials to SSH into the slave with. Credentials can be any
# of the following:
#
# * username which maps to a valid Jenkins credentials instance.
# * UUID of a Jenkins credentials instance.
# * A `Chef::Resource::JenkinsCredentials` instance.
#
# @return [String]
#
def parsed_credentials
  if credentials.is_a?(Resource::JenkinsCredentials)
    credentials.send(:id)
  else
    credentials.to_s
  end
end

def load_current_resource
  @current_resource ||= Resource::JenkinsSshSlave.new(new_resource.name)

  super

  if current_slave
    @current_resource.host(current_slave[:host])
    @current_resource.port(current_slave[:port])
    @current_resource.credentials(current_slave[:credentials])
    @current_resource.jvm_options(current_slave[:jvm_options])
    @current_resource.java_path(current_slave[:java_path])
    @current_resource.launch_timeout(current_slave[:launch_timeout])
    @current_resource.ssh_retries(current_slave[:ssh_retries])
    @current_resource.ssh_wait_retries(current_slave[:ssh_wait_retries])
  end

  @current_resource
end

action_class do
  #
  # @see Chef::Resource::JenkinsSlave#launcher_groovy
  # @see https://github.com/jenkinsci/ssh-credentials-plugin/blob/master/src/main/java/com/cloudbees/jenkins/plugins/sshcredentials/impl/BasicSSHUserPrivateKey.java
  # @see https://github.com/jenkinsci/ssh-slaves-plugin/blob/master/src/main/java/hudson/plugins/sshslaves/SSHLauncher.java
  #
  def launcher_groovy
    <<-EOH.gsub(/^ {8}/, '')
      import hudson.plugins.sshslaves.verifiers.*
      #{credential_lookup_groovy('credentials')}
      launcher =
        new hudson.plugins.sshslaves.SSHLauncher(
          #{convert_to_groovy(new_resource.host)},
          #{convert_to_groovy(new_resource.port)},
          #{convert_to_groovy(new_resource.credentials)},
          #{convert_to_groovy(new_resource.jvm_options)},
          #{convert_to_groovy(new_resource.java_path)},
          #{convert_to_groovy(new_resource.command_prefix)},
          #{convert_to_groovy(new_resource.command_suffix)},
          #{convert_to_groovy(new_resource.launch_timeout)},
          #{convert_to_groovy(new_resource.ssh_retries)},
          #{convert_to_groovy(new_resource.ssh_wait_retries)},
          new ManuallyTrustedKeyVerificationStrategy(false)
        )
    EOH
  end

  #
  # @see Chef::Resource::JenkinsSlave#attribute_to_property_map
  #
  def attribute_to_property_map
    map = {
      host: 'slave.launcher.host',
      port: 'slave.launcher.port',
      jvm_options: 'slave.launcher.jvmOptions',
      java_path: 'slave.launcher.javaPath',
      command_prefix: 'slave.launcher.prefixStartSlaveCmd',
      command_suffix: 'slave.launcher.suffixStartSlaveCmd',
      launch_timeout: 'slave.launcher.launchTimeoutSeconds',
      ssh_retries: 'slave.launcher.maxNumRetries',
      ssh_wait_retries: 'slave.launcher.retryWaitTime',
    }

    map[:credentials] = 'slave.launcher.credentialsId'

    map
  end

  #
  # A Groovy snippet that will set the requested local Groovy variable
  # to an instance of the credentials represented by
  # `new_resource.parsed_credentials`.
  #
  # @param [String] groovy_variable_name
  # @return [String]
  #
  def credential_lookup_groovy(groovy_variable_name = 'credentials_id')
    <<-EOH.gsub(/^ {8}/, '')
      #{credentials_for_id_groovy(new_resource.parsed_credentials, groovy_variable_name)}
    EOH
  end
end
