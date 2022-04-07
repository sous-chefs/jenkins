unified_mode true
# require_relative 'credentials'

property :description,
          String,
          name_property: true
property :secret,
          String,
          required: true

def load_current_resource
  @current_resource ||= Resource::JenkinsSecretTextCredentials.new(new_resource.name)

  super

  @current_resource.secret(current_credentials[:secret]) if current_credentials

  @current_credentials
end

action_class do
  #
  # @see Chef::Resource::JenkinsCredentials#credentials_groovy
  # @see https://github.com/jenkinsci/plain-credentials-plugin/blob/master/src/main/java/org/jenkinsci/plugins/plaincredentials/impl/StringCredentialsImpl.java
  #
  def credentials_groovy
    <<-EOH.gsub(/^ {8}/, '')
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
    <<-EOH.gsub(/^ {8}/, '')
      #{credentials_for_secret_groovy(new_resource.secret, new_resource.description, groovy_variable_name)}
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

    attribute_to_property_map.each_key do |key|
      wanted_credentials[key] = new_resource.send(key)
    end

    # Don't compare the ID as it is generated
    current_credentials.dup.tap { |c| c.delete(:id) } == convert_blank_values_to_nil(wanted_credentials)
  end
end
