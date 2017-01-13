#
# Cookbook:: jenkins
# HWRP:: credentials_secret_text
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

require_relative 'credentials'

class Chef
  class Resource::JenkinsSecretTextCredentials < Resource::JenkinsCredentials
    resource_name :jenkins_secret_text_credentials

    # Chef attributes
    identity_attr :description

    # Attributes
    attribute :description,
              kind_of: String,
              name_attribute: true
    attribute :secret,
              kind_of: String,
              required: true
  end
end

class Chef
  class Provider::JenkinsSecretTextCredentials < Provider::JenkinsCredentials
    use_inline_resources

    provides :jenkins_secret_text_credentials

    def load_current_resource
      @current_resource ||= Resource::JenkinsSecretTextCredentials.new(new_resource.name)

      super

      if current_credentials
        @current_resource.secret(current_credentials[:secret])
      end

      @current_credentials
    end

    private

    #
    # @see Chef::Resource::JenkinsCredentials#credentials_groovy
    # @see https://github.com/jenkinsci/plain-credentials-plugin/blob/master/src/main/java/org/jenkinsci/plugins/plaincredentials/impl/StringCredentialsImpl.java
    #
    def credentials_groovy
      <<-EOH.gsub(/ ^{8}/, '')
        import hudson.util.Secret;
        import com.cloudbees.plugins.credentials.CredentialsScope;
        import org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl;

        credentials = new StringCredentialsImpl(
          CredentialsScope.GLOBAL,
          #{convert_to_groovy(new_resource.id)},
          #{convert_to_groovy(new_resource.description)},
          new Secret(#{convert_to_groovy(new_resource.secret)}),
        )
      EOH
    end

    #
    # @see Chef::Resource::JenkinsCredentials#fetch_credentials_groovy
    #
    def fetch_existing_credentials_groovy(groovy_variable_name)
      <<-EOH.gsub(/ ^{8}/, '')
        #{credentials_for_secret_groovy(new_resource.secret, new_resource.description, groovy_variable_name)}
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
          secret:credentials.secret
        ]
      EOH
    end

    #
    # @see Chef::Resource::JenkinsCredentials#attribute_to_property_map
    #
    def attribute_to_property_map
      { secret: 'credentials.secret.plainText' }
    end

    #
    # @see Chef::Resource::JenkinsCredentials#correct_config?
    #
    def correct_config?
      wanted_credentials = {
        description: new_resource.description,
        secret: new_resource.secret,
      }

      attribute_to_property_map.keys.each do |key|
        wanted_credentials[key] = new_resource.send(key)
      end

      # Don't compare the ID as it is generated
      current_credentials.dup.tap { |c| c.delete(:id) } == convert_blank_values_to_nil(wanted_credentials)
    end
  end
end
