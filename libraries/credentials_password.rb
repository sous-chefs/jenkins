#
# Cookbook Name:: jenkins
# HWRP:: credentials_password
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

require_relative 'credentials'
require_relative '_params_validate'

class Chef
  class Resource::JenkinsPasswordCredentials < Resource::JenkinsCredentials
    # Chef attributes
    provides :jenkins_password_credentials

    # Set the resource name
    self.resource_name = :jenkins_password_credentials

    # Actions
    actions :create, :delete
    default_action :create

    # Attributes
    attribute :password,
      kind_of: String,
      required: true
  end
end

class Chef
  class Provider::JenkinsPasswordCredentials < Provider::JenkinsCredentials
    def load_current_resource
      @current_resource ||= Resource::JenkinsPasswordCredentials.new(new_resource.name)

      super

      if current_credentials
        @current_resource.password(current_credentials[:password])
      end

      @current_credentials
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

        credentials = new UsernamePasswordCredentialsImpl(
          CredentialsScope.GLOBAL,
          #{convert_to_groovy(new_resource.id)},
          #{convert_to_groovy(new_resource.description)},
          #{convert_to_groovy(new_resource.username)},
          #{convert_to_groovy(new_resource.password)}
        )
      EOH
    end

    #
    # @see Chef::Resource::JenkinsCredentials#attribute_to_property_map
    #
    def attribute_to_property_map
      {
        password: 'credentials.password.plainText',
      }
    end
  end
end

Chef::Platform.set(
  resource: :jenkins_password_credentials,
  provider: Chef::Provider::JenkinsPasswordCredentials
)
