#
# Cookbook Name:: jenkins
# HWRP:: credentials_password
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

class Chef
  class Resource::JenkinsPrivateKeyCredentials < Resource::JenkinsCredentials
    provides :jenkins_private_key_credentials

    def initialize(name, run_context = nil)
      super

      @resource_name = :jenkins_private_key_credentials
      @provider = Provider::JenkinsPrivateKeyCredentials
    end

    #
    # Private key of the credentials . This should be the actual key
    # contents (as opposed to the path to a private key file) in OpenSSH
    # format.
    #
    # @param [String] arg
    # @return [String]
    #
    def private_key(arg = nil)
      if arg.nil?
        @private_key
      else
        arg = OpenSSL::PKey::RSA.new(arg).to_pem unless arg.empty?
        set_or_return(:private_key, arg, kind_of: String)
      end
    end

    #
    # Passphrase for the private key of the credentials.
    #
    # @param [String] arg
    # @return [String]
    #
    def passphrase(arg = nil)
      set_or_return(:passphrase, arg, kind_of: String)
    end
  end
end

class Chef
  class Provider::JenkinsPrivateKeyCredentials < Provider::JenkinsCredentials
    def load_current_resource
      @current_resource ||= Resource::JenkinsPrivateKeyCredentials.new(new_resource.name)

      super

      if current_credentials
        @current_resource.private_key(current_credentials[:private_key])
      end
    end

    protected

    #
    # @see Chef::Resource::JenkinsCredentials#credentials_groovy
    # @see https://github.com/jenkinsci/ssh-credentials-plugin/blob/master/src/main/java/com/cloudbees/jenkins/plugins/sshcredentials/impl/BasicSSHUserPrivateKey.java
    #
    def credentials_groovy
      <<-EOH.gsub(/ ^{8}/, '')
        import com.cloudbees.plugins.credentials.*
        import com.cloudbees.jenkins.plugins.sshcredentials.impl.*

        private_key = """#{new_resource.private_key}
        """

        credentials = new BasicSSHUserPrivateKey(
          CredentialsScope.GLOBAL,
          #{convert_to_groovy(new_resource.id)},
          #{convert_to_groovy(new_resource.username)},
          new BasicSSHUserPrivateKey.DirectEntryPrivateKeySource(private_key),
          #{convert_to_groovy(new_resource.passphrase)},
          #{convert_to_groovy(new_resource.description)}
        )
      EOH
    end

    #
    # @see Chef::Resource::JenkinsCredentials#attribute_to_property_map
    #
    def attribute_to_property_map
      {
        private_key: 'credentials.privateKey',
        passphrase: 'credentials.passphrase.plainText'
      }
    end

    #
    # @see Chef::Resource::JenkinsCredentials#current_credentials
    #
    def current_credentials
      super

      # Normalize the private key
      if @current_credentials && @current_credentials[:private_key]
        @current_credentials[:private_key] = OpenSSL::PKey::RSA.new(@current_credentials[:private_key]).to_pem
      end

      @current_credentials
    end
  end
end
