class Chef
  class Resource::JenkinsBlazemeterCredentials < Resource::JenkinsCredentials
    resource_name :jenkins_blazemeter_credentials

    # Chef attributes
    identity_attr :description

    # Attributes
    attribute :description,
              kind_of: String,
              name_attribute: true
    attribute :api_key,
              kind_of: String,
              required: true
  end
end

class Chef
  class Provider::JenkinsBlazemeterCredentials < Provider::JenkinsCredentials
    use_inline_resources

    provides :jenkins_blazemeter_credentials

    def load_current_resource
      @current_resource ||= Resource::JenkinsBlazemeterCredentials.new(new_resource.name)

      super

      if current_credentials
        @current_resource.api_key(current_credentials[:api_key])
      end

      @current_credentials
    end

    private

    def credentials_groovy
      <<-EOH.gsub(/ ^{8}/, '')
        import hudson.plugins.blazemeter.BlazemeterCredentialImpl
        credentials = new hudson.plugins.blazemeter.BlazemeterCredentialImpl(
          #{convert_to_groovy(new_resource.api_key)}, #{convert_to_groovy(new_resource.description)})
      EOH
    end

    def fetch_existing_credentials_groovy(groovy_variable_name)
      <<-EOH.gsub(/ ^{8}/, '')
#{blazemeter_credentials_for_description_groovy(new_resource.description, groovy_variable_name)}
      EOH
    end

    def resource_attributes_groovy(groovy_variable_name)
      <<-EOH.gsub(/ ^{8}/, '')
#{groovy_variable_name} = [
          id:credentials.id,
          description:credentials.description,
          api_key:credentials.apiKey
        ]
      EOH
    end

    #
    # @see Chef::Resource::JenkinsCredentials#attribute_to_property_map
    #
    def attribute_to_property_map
      { api_key: 'credentials.apiKey' }
    end

    #
    # @see Chef::Resource::JenkinsCredentials#correct_config?
    #
    def correct_config?
      wanted_credentials = {
          description: new_resource.description,
          api_key: new_resource.api_key
      }

      attribute_to_property_map.keys.each do |key|
        wanted_credentials[key] = new_resource.send(key)
      end

      # Don't compare the ID as it is generated
      current_credentials.dup.tap { |c| c.delete(:id) } == convert_blank_values_to_nil(wanted_credentials)
    end

    def blazemeter_credentials_for_description_groovy(description, groovy_variable_name)
      <<-EOH.gsub(/ ^{8}/, '')
        import jenkins.model.Jenkins;
        import com.cloudbees.plugins.credentials.CredentialsProvider
        import hudson.plugins.blazemeter.BlazemeterCredentialImpl
        available_credentials =
          CredentialsProvider.lookupCredentials(
            BlazemeterCredentialImpl.class,
            Jenkins.getInstance(),
            hudson.security.ACL.SYSTEM
          ).findAll({
            it.description == #{convert_to_groovy(description)}
          })
        #{groovy_variable_name} = available_credentials.size() > 0 ? available_credentials[0] : null
      EOH
    end
  end
end