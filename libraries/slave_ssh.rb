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

require 'base64'
require 'openssl'
require_relative 'slave'

class Chef
  class Resource::JenkinsSSHSlave < Resource::JenkinsSlave
    provides :jenkins_ssh_slave

    def initialize(name, run_context = nil)
      super

      # Set the resource name and provider
      @resource_name = :jenkins_ssh_slave
      @provider = Provider::JenkinsSSHSlave

      # Set the name attribute and default attributes
      @port           = 22
      @command_prefix = nil
      @command_suffix = nil
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
    # The SSH command prefix.
    #
    # @param [String] arg
    # @return [String]
    #
    def command_prefix(arg = nil)
      set_or_return(:command_prefix, arg, kind_of: String)
    end

    #
    # The SSH command suffix.
    #
    # @param [String] arg
    # @return [String]
    #
    def command_suffix(arg = nil)
      set_or_return(:command_suffix, arg, kind_of: String)
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
    end

    #
    # @see Chef::Resource::JenkinsSlave#action_create
    #
    def action_create
      parent_remote_fs_dir_resource
      group_resource.run_action(:create)
      user_resource.run_action(:create)
      remote_fs_dir_resource.run_action(:create)
      ssh_dir_resource.run_action(:create)
      authorized_keys_file_resource.run_action(:create)

      super
    end

    protected

    #
    # @see Chef::Resource::JenkinsSlave#launcher_groovy
    # @see https://github.com/jenkinsci/ssh-credentials-plugin/blob/master/src/main/java/com/cloudbees/jenkins/plugins/sshcredentials/impl/BasicSSHUserPrivateKey.java
    # @see https://github.com/jenkinsci/ssh-slaves-plugin/blob/master/src/main/java/hudson/plugins/sshslaves/SSHLauncher.java
    #
    def launcher_groovy
      <<-EOH.gsub(/ ^{8}/, '')
        #{credential_lookup_groovy('credentials_id')}
        launcher =
          new hudson.plugins.sshslaves.SSHLauncher(
            #{convert_to_groovy(new_resource.host)},
            #{convert_to_groovy(new_resource.port)},
            credentials_id,
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

      if new_resource.credentials.match(UUID_REGEX)
        map[:credentials] = 'slave.launcher.credentialsId'
      else
        map[:credentials] = 'hudson.plugins.sshslaves.SSHLauncher.lookupSystemCredentials(slave.launcher.credentialsId).username'
      end
      map
    end

    private

    #
    # A Groovy snippet that will set the requested local Groovy variable
    # to an instance of the credentials represented by `new_resource.credentials`.
    #
    # @param [String] groovy_variable_name
    # @return [String]
    #
    def credential_lookup_groovy(groovy_variable_name = 'credentials_id')
      if new_resource.credentials.match(UUID_REGEX)
        "#{groovy_variable_name} = #{convert_to_groovy(new_resource.credentials)}"
      else
        <<-EOH.gsub(/ ^{10}/, '')
          #{credentials_for_username_groovy(new_resource.credentials, 'user_credentials')}
          #{groovy_variable_name} = user_credentials.id
        EOH
      end
    end

    #
    # Looks up the private key from the slave's credentials.
    #
    # @return [String]
    #
    def private_key
      return @private_key if @private_key
      json = executor.groovy! <<-EOH.gsub(/ ^{8}/, '')
        #{credential_lookup_groovy('credentials_id')}
        credentials =
          hudson.plugins.sshslaves.SSHLauncher.lookupSystemCredentials(credentials_id)

        output = [
          private_key:credentials.privateKey
        ]

        builder = new groovy.json.JsonBuilder(output)
        println(builder)
      EOH
      output = JSON.parse(json, symbolize_names: true)
      @private_key = output[:private_key]
    end

    #
    # Extracts a public key from the slave's private key encoded in SSH
    # Public Key format.
    #
    # @return [String]
    #
    def ssh_pub_key
      return @ssh_pub_key if @ssh_pub_key
      # Load net-ssh as it adds `#ssh_type` and `#to_blob` methods to
      # `OpenSSL::PKey::RSA`.
      #
      # More info at: http://stackoverflow.com/a/10375654/80030
      require 'net/ssh'
      # extract the public key from the private key
      public_key = OpenSSL::PKey::RSA.new(private_key).public_key
      ssh_pub_key_parts =  [public_key.ssh_type]
      ssh_pub_key_parts << Base64.encode64(public_key.to_blob).gsub("\n", '')
      @ssh_pub_key = ssh_pub_key_parts.join("\s")
    end

    # Embedded Resources

    def ssh_dir_resource
      return @ssh_dir_resource if @ssh_dir_resource
      dot_ssh_path = ::File.join(new_resource.remote_fs, '.ssh')
      @ssh_dir_resource = Chef::Resource::Directory.new(dot_ssh_path, run_context)
      @ssh_dir_resource.owner(new_resource.user)
      @ssh_dir_resource.group(new_resource.group)
      @ssh_dir_resource.recursive(true)
      @ssh_dir_resource.mode('0700')
      @ssh_dir_resource
    end

    def authorized_keys_file_resource
      return @authorized_keys_file_resource if @authorized_keys_file_resource
      auhtorized_key_path = ::File.join(ssh_dir_resource.path, 'authorized_keys')
      @authorized_keys_file_resource = Chef::Resource::File.new(auhtorized_key_path, run_context)
      @authorized_keys_file_resource.owner(new_resource.user)
      @authorized_keys_file_resource.group(new_resource.group)
      @authorized_keys_file_resource.mode('0600')
      @authorized_keys_file_resource.content(ssh_pub_key)
      @authorized_keys_file_resource
    end
  end
end
