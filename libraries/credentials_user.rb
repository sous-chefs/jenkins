#
# Cookbook:: jenkins
# HWRP:: credentials_user
#
# Author:: Miguel Ferreira <mferreira@schubergphilis.com>
#
# Copyright:: 2015-2016, Schuberg Philis
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

# This is required to appease Travis-CI
# https://travis-ci.org/chef-cookbooks/jenkins/builds/197337230
require_relative 'credentials'

class Chef
  class Resource::JenkinsUserCredentials < Resource::JenkinsCredentials
    attribute :description,
              kind_of: String,
              default: lazy { |new_resource| "Credentials for #{new_resource.username} - created by Chef" }
  end
end

class Chef
  class Provider::JenkinsUserCredentials < Provider::JenkinsCredentials
    use_inline_resources
    include Jenkins::Helper

    def load_current_resource
      @current_resource ||= Resource::JenkinsCredentialsUser.new(new_resource.name)

      super

      if current_credentials
        @current_resource.username(current_credentials[:username])
      end

      @current_resource
    end

    private

    #
    # @see Chef::Resource::JenkinsCredentials#save_credentials_groovy
    #
    def fetch_existing_credentials_groovy(groovy_variable_name)
      <<-EOH.gsub(/ ^{8}/, '')
        #{credentials_for_id_groovy(new_resource.id, groovy_variable_name)}
      EOH
    end

    #
    # @see Chef::Resource::JenkinsCredentials#resource_attributes_groovy
    #
    def resource_attributes_groovy(groovy_variable_name)
      <<-EOH.gsub(/ ^{8}/, '')
        #{groovy_variable_name} = [
          id:credentials.id,
          description:credentials.description,
          username:credentials.username
        ]
      EOH
    end

    #
    # @see Chef::Resource::JenkinsCredentials#correct_config?
    #
    def correct_config?
      wanted_credentials = {
        description: new_resource.description,
        username: new_resource.username,
      }

      attribute_to_property_map.keys.each do |key|
        wanted_credentials[key] = new_resource.send(key)
      end

      # Don't compare the ID as it is generated
      current_credentials.dup.tap { |c| c.delete(:id) } == convert_blank_values_to_nil(wanted_credentials)
    end
  end
end
