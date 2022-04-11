#
# Cookbook:: jenkins
# HWRP:: credentials_file
#
# Author:: Olivier Abdesselam <olivier.abdesselam@teads.tv>
#
# Copyright:: 2018-2019, Teads
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
  class Resource::JenkinsFileCredentials < Resource::JenkinsCredentials
    include Jenkins::Helper

    resource_name :jenkins_file_credentials # Still needed for Chef 15 and below
    provides :jenkins_file_credentials

    attribute :description,
              kind_of: String,
              default: lazy { |new_resource| "Credentials for #{new_resource.filename} - created by Chef" }

    # Attributes
    attribute :filename,
              kind_of: String,
              name_attribute: true
    attribute :data,
              kind_of: String,
              required: true
  end
end

class Chef
  class Provider::JenkinsFileCredentials < Provider::JenkinsCredentials
    include Jenkins::Helper
    provides :jenkins_file_credentials

    def load_current_resource
      @current_resource ||= Resource::JenkinsFileCredentials.new(new_resource.name)

      super

      @current_resource.filename(current_credentials[:filename]) if current_credentials

      @current_resource
    end

    private

    #
    # @see Chef::Resource::JenkinsCredentials#save_credentials_groovy
    #
    def fetch_existing_credentials_groovy(groovy_variable_name)
      <<-EOH.gsub(/^ {8}/, '')
        #{credentials_for_id_groovy(new_resource.id, groovy_variable_name)}
      EOH
    end

    #
    # @see Chef::Resource::JenkinsCredentials#resource_attributes_groovy
    #
    def resource_attributes_groovy(groovy_variable_name)
      <<-EOH.gsub(/^ {8}/, '')
        #{groovy_variable_name} = [
          id:credentials.id,
          description:credentials.description,
          filename:credentials.filename,
        ]
      EOH
    end

    #
    # @see Chef::Resource::JenkinsCredentials#correct_config?
    #
    def correct_config?
      wanted_credentials = {
        description: new_resource.description,
        filename: new_resource.filename,
      }

      attribute_to_property_map.each_key do |key|
        wanted_credentials[key] = new_resource.send(key)
      end

      # Don't compare the ID as it is generated
      current_credentials.dup.tap { |c| c.delete(:id) } == convert_blank_values_to_nil(wanted_credentials)
    end

    #
    # @see Chef::Resource::JenkinsCredentials#credentials_groovy
    # @see https://github.com/jenkinsci/ssh-credentials-plugin/blob/master/src/main/java/com/cloudbees/jenkins/plugins/sshcredentials/impl/BasicSSHUserPrivateKey.java
    #
    def credentials_groovy
      <<-EOH.gsub(/^ {8}/, '')
        import com.cloudbees.plugins.credentials.*
        import org.jenkinsci.plugins.plaincredentials.impl.*

        credentials = new FileCredentialsImpl(
          CredentialsScope.GLOBAL,
          #{convert_to_groovy(new_resource.id)},
          #{convert_to_groovy(new_resource.description)},
          #{convert_to_groovy(new_resource.filename)},
          SecretBytes.fromBytes(#{convert_to_groovy(new_resource.data)}.getBytes())
        )
      EOH
    end
  end
end
