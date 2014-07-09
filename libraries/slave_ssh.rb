#
# Cookbook Name:: jenkins
# HWRP:: ssh_slave
#
# Author:: Seth Chisamore <schisamo@getchef.com>
#
# Copyright 2013-2014, Chef Software, Inc.
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

require_relative '_params_validate'
require_relative 'slave'
require_relative 'credentials'

class Chef
  class Resource::JenkinsSSHSlave < Resource::JenkinsSlave
    # Chef attributes
    provides :jenkins_ssh_slave

    # Set the resource name
    self.resource_name = :jenkins_ssh_slave

    # Actions
    actions :create, :delete, :connect, :disconnect, :online, :offline
    default_action :create

    # Attributes
    attribute :host,
      kind_of: String
    attribute :port,
      kind_of: Integer,
      default: 22
    attribute :credentials,
      kind_of: [Resource::JenkinsCredentials, String]
    attribute :command_prefix,
      kind_of: String
    attribute :command_suffix,
      kind_of: String

    #
    # The credentials to SSH into the slave with. Credentials can be any
    # of the following:
    #
    # * username which maps to a valid Jenkins credentials instance.
    # * UUID of a Jenkins credentials instance.
    # * A `Chef::Resource::JenkinsCredentials` instnace.
    #
    # @return [String]
    #
    def parsed_credentials
      if credentials.is_a?(Resource::JenkinsCredentials)
        credentials.send(:username)
      else
        credentials.to_s
      end
    end
  end
end

class Chef
  class Provider::JenkinsSSHSlave < Provider::JenkinsSlave
    def load_current_resource
      @current_resource ||= Resource::JenkinsSSHSlave.new(new_resource.name)

      super

      if current_slave
        @current_resource.host(current_slave[:host])
        @current_resource.port(current_slave[:port])
        @current_resource.credentials(current_slave[:credentials])
        @current_resource.jvm_options(current_slave[:jvm_options])
      end

      @current_resource
    end

    protected

    #
    # @see Chef::Resource::JenkinsSlave#launcher_groovy
    # @see https://github.com/jenkinsci/ssh-credentials-plugin/blob/master/src/main/java/com/cloudbees/jenkins/plugins/sshcredentials/impl/BasicSSHUserPrivateKey.java
    # @see https://github.com/jenkinsci/ssh-slaves-plugin/blob/master/src/main/java/hudson/plugins/sshslaves/SSHLauncher.java
    #
    def launcher_groovy
      <<-EOH.gsub(/ ^{8}/, '')
        #{credential_lookup_groovy('credentials')}
        launcher =
          new hudson.plugins.sshslaves.SSHLauncher(
            #{convert_to_groovy(new_resource.host)},
            #{convert_to_groovy(new_resource.port)},
            credentials,
            #{convert_to_groovy(new_resource.jvm_options)},
            null,
            #{convert_to_groovy(new_resource.command_prefix)},
            #{convert_to_groovy(new_resource.command_suffix)}
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
        command_prefix: 'slave.launcher.prefixStartSlaveCmd',
        command_suffix: 'slave.launcher.suffixStartSlaveCmd',
      }

      if new_resource.parsed_credentials.match(UUID_REGEX)
        map[:credentials] = 'slave.launcher.credentialsId'
      else
        map[:credentials] = 'slave.launcher.credentialsId == null ? null : hudson.plugins.sshslaves.SSHLauncher.lookupSystemCredentials(slave.launcher.credentialsId).username'
      end
      map
    end

    private

    #
    # A Groovy snippet that will set the requested local Groovy variable
    # to an instance of the credentials represented by
    # `new_resource.parsed_credentials`.
    #
    # @param [String] groovy_variable_name
    # @return [String]
    #
    def credential_lookup_groovy(groovy_variable_name = 'credentials_id')
      if new_resource.parsed_credentials.match(UUID_REGEX)
        "#{groovy_variable_name} = hudson.plugins.sshslaves.SSHLauncher.lookupSystemCredentials(#{convert_to_groovy(new_resource.parsed_credentials)})"
      else
        <<-EOH.gsub(/ ^{10}/, '')
          #{credentials_for_username_groovy(new_resource.parsed_credentials, groovy_variable_name)}
        EOH
      end
    end
  end
end

Chef::Platform.set(
  resource: :jenkins_ssh_slave,
  provider: Chef::Provider::JenkinsSSHSlave
)
