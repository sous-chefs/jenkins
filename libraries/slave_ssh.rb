#
# Cookbook Name:: jenkins
# HWRP:: ssh_slave
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

require_relative 'slave'

#
#
#
class Chef
  class Resource::JenkinsSSHSlave < Resource::JenkinsSlave
    provides :jenkins_ssh_slave

    def initialize(name, run_context = nil)
      super

      # Set the resource name and provider
      @resource_name = :jenkins_ssh_slave
      @provider = Provider::JenkinsSSHSlave

      # Set the name attribute and default attributes
      @port = 22
    end

    #
    # The hostname of the slave. This can also be an IP address.
    #
    # @param [String] arg
    # @return [String]
    #
    def host(arg = nil)
      set_or_return(:host, arg, kind_of: String)
    end

    #
    # The port on the slave on which the `sshd` service is listening.
    #
    # @param [Integer] arg
    # @return [Integer]
    #
    def port(arg = nil)
      set_or_return(:port, arg, kind_of: Integer)
    end

    #
    # The credentials to SSH into the slave with. Credentials can be any
    # of the following:
    #
    # * username which maps to a valid Jenkins credentials instance.
    # * UUID of a Jenkins credentials instance.
    # * A `Chef::Resource::JenkinsCredentials` instnace.
    #
    # @param [String] arg
    # @return [String]
    #
    def credentials(arg = nil)
      # Extract the username from a Chef::Resource::JenkinsCredentials
      # instance
      if arg.kind_of? Chef::Resource::JenkinsCredentials
        arg = arg.send(:username)
      end
      set_or_return(:credentials, arg, kind_of: String)
    end

    #
    # JVM Options used to launch the slave JVM.
    #
    # @param [String] arg
    # @return [String]
    #
    def jvm_options(arg=nil)
      set_or_return(:jvm_options, arg, kind_of: String)
    end

  end
end

#
#
#
class Chef
  class Provider::JenkinsSSHSlave < Provider::JenkinsSlave

    def load_current_resource
      @current_resource ||= Resource::JenkinsSSHSlave.new(new_resource.name)

      set_base_attributes

      if current_slave
        @current_resource.host(current_slave[:host])
        @current_resource.port(current_slave[:port])
        @current_resource.credentials(current_slave[:credentials])
        @current_resource.jvm_options(current_slave[:jvm_options])
      end
    end

    protected

    #
    # @see Chef::Resource::JenkinsSlave#launcher_groovy
    # @see https://github.com/jenkinsci/ssh-credentials-plugin/blob/master/src/main/java/com/cloudbees/jenkins/plugins/sshcredentials/impl/BasicSSHUserPrivateKey.java
    # @see https://github.com/jenkinsci/ssh-slaves-plugin/blob/master/src/main/java/hudson/plugins/sshslaves/SSHLauncher.java
    #
    def launcher_groovy
      credential_lookup_groovy = if new_resource.credentials.match(UUID_REGEX)
                                   "credentials_id = #{convert_to_groovy(new_resource.credentials)}"
                                 else
                                   <<-EOH.gsub(/ ^{37}/, '')
                                    #{credentials_for_username_groovy(new_resource.credentials, 'user_credentials')}
                                    credentials_id = user_credentials.id
                                   EOH
                                 end
      <<-EOH.gsub(/ ^{8}/, '')
        #{credential_lookup_groovy}
        launcher = new hudson.plugins.sshslaves.SSHLauncher(#{convert_to_groovy(new_resource.host)},
                                                            #{convert_to_groovy(new_resource.port)},
                                                            credentials_id,
                                                            #{convert_to_groovy(new_resource.jvm_options)},
                                                            null,
                                                            null,
                                                            null)
      EOH
    end

    #
    # @see Chef::Resource::JenkinsSlave#attribute_to_property_map
    #
    def attribute_to_property_map
      map = {host: 'slave.launcher.host',
             port: 'slave.launcher.port',
             jvm_options: 'slave.launcher.jvmOptions'}
      if new_resource.credentials.match(UUID_REGEX)
        map[:credentials] = 'slave.launcher.credentialsId'
      else
        map[:credentials] = 'hudson.plugins.sshslaves.SSHLauncher.lookupSystemCredentials(slave.launcher.credentialsId).username'
      end
      map
    end

  end
end
