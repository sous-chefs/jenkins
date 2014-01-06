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
  class Resource::JenkinsPasswordCredentials < Resource::JenkinsCredentials
    provides :jenkins_password_credentials

    def initialize(name, run_context = nil)
      super

      @resource_name = :jenkins_password_credentials
      @provider = Provider::JenkinsPasswordCredentials
    end

    #
    # The password of the credentials.
    #
    # @param [String] arg
    # @return [String]
    #
    def password(arg = nil)
      set_or_return(:password, arg, kind_of: String)
    end
  end
end

class Chef
  class Provider::JenkinsPasswordCredentials < Provider::JenkinsCredentials
    def load_current_resource
      @current_resource ||= Resource::JenkinsPasswordCredentials.new(new_resource.name)

      if current_credentials
        @current_resource.password(current_credentials[:password])
      end

      super
    end

    protected

    #
    # @see Chef::Resource::JenkinsCredentials#credentials_groovy
    # @see https://github.com/jenkinsci/credentials-plugin/blob/master/src/main/java/com/cloudbees/plugins/credentials/impl/UsernamePasswordCredentialsImpl.java
    #
    def credentials_groovy
      <<-EOH.gsub(/ ^{8}/, '')
        import com.cloudbees.plugins.credentials.*
        import com.cloudbees.plugins.credentials.impl.*

        credentials = new UsernamePasswordCredentialsImpl(CredentialsScope.GLOBAL,
                                                          #{convert_to_groovy(new_resource.id)},
                                                          #{convert_to_groovy(new_resource.description)},
                                                          #{convert_to_groovy(new_resource.username)},
                                                          #{convert_to_groovy(new_resource.password)})
      EOH
    end

    #
    # @see Chef::Resource::JenkinsCredentials#attribute_to_property_map
    #
    def attribute_to_property_map
      {
        password: 'credentials.password.plainText'
      }
    end
  end
end
