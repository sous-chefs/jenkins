#
# Cookbook:: jenkins
# Resource:: credentials_githubapp
#
# Author:: Vytautas Stankevicius <vytautas.stankevicius@vinted.com>
#
# Copyright:: 2021-2024, Vinted
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

class Chef
  class Resource::JenkinsGitHubAppCredentials < Resource::JenkinsCredentials
    include Jenkins::Helper

    resource_name :jenkins_githubapp_credentials # Still needed for Chef 15 and below
    provides :jenkins_githubapp_credentials

    # Attributes
    attribute :description,
              kind_of: String,
              default: lazy { |new_resource| "Credentials for GitHub App #{new_resource.app_id} - created by Chef" }
    attribute :app_id,
              kind_of: String,
              name_attribute: true
    attribute :private_key_pkcs8_pem,
              kind_of: String,
              required: true
    attribute :owner,
              kind_of: String,
              required: true
  end
end

class Chef
  class Provider::JenkinsGitHubAppCredentials < Provider::JenkinsCredentials
    include Jenkins::Helper
    provides :jenkins_githubapp_credentials

    def load_current_resource
      @current_resource ||= Resource::JenkinsGitHubAppCredentials.new(new_resource.name)

      super

      @current_resource.private_key_pkcs8_pem(current_credentials[:private_key_pkcs8_pem]) if current_credentials

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
          app_id:credentials.username
        ]
      EOH
    end

    #
    # @see Chef::Resource::JenkinsCredentials#correct_config?
    #
    def correct_config?
      wanted_credentials = {
        description: new_resource.description,
        app_id: new_resource.app_id,
      }

      attribute_to_property_map.each_key do |key|
        wanted_credentials[key] = new_resource.send(key)
      end

      # Don't compare the ID as it is generated
      current_credentials.dup.tap { |c| c.delete(:id) } == convert_blank_values_to_nil(wanted_credentials)
    end

    #
    # @see Chef::Resource::JenkinsCredentials#credentials_groovy
    # @see https://github.com/jenkinsci/github-branch-source-plugin/blob/master/src/main/java/org/jenkinsci/plugins/github_branch_source/GitHubAppCredentials.java
    #
    def credentials_groovy
      <<-EOH.gsub(/^ {8}/, '')
        import hudson.util.Secret
        import org.jenkinsci.plugins.github_branch_source.*

        private_key = """#{new_resource.private_key_pkcs8_pem}
        """

        githubAppPrivateKey = Secret.fromString(private_key)
        credentials = new GitHubAppCredentials(
          CredentialsScope.GLOBAL,
          #{convert_to_groovy(new_resource.id)},
          #{convert_to_groovy(new_resource.description)},
          #{convert_to_groovy(new_resource.app_id)},
          githubAppPrivateKey

        )

        String orgOwner = #{convert_to_groovy(new_resource.owner)}
        credentials.setOwner(orgOwner)

      EOH
    end

    #
    # @see Chef::Resource::JenkinsCredentials#attribute_to_property_map
    #
    def attribute_to_property_map
      {
        private_key_pkcs8_pem: 'credentials.privateKey.plainText',
      }
    end
  end
end
