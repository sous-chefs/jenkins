unified_mode true

include Jenkins::Helper
provides :jenkins_file_credentials

property :description,
          String,
          default: lazy { |new_resource| "Credentials for #{new_resource.filename} - created by Chef" }

property :filename,
          String,
          name_property: true
property :data,
          String,
          required: true

use 'partials/_credentials'

def load_current_resource
  @current_resource ||= Resource::JenkinsFileCredentials.new(new_resource.name)

  super

  @current_resource.filename(current_credentials[:filename]) if current_credentials

  @current_resource
end

action_class do
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
