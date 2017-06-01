class Chef
  class Resource::JenkinsSauceOndemandCredentials < Resource::JenkinsUserCredentials
    resource_name :jenkins_sauce_ondemand_credentials

    # Attributes
    attribute :username,
              kind_of: String,
              name_attribute: true
    attribute :api_key,
              kind_of: String,
              required: true
  end
end

class Chef
  class Provider::JenkinsSauceOndemandCredentials < Provider::JenkinsUserCredentials
    use_inline_resources
    provides :jenkins_sauce_ondemand_credentials

    def load_current_resource
      @current_resource ||= Resource::JenkinsSauceOndemandCredentials.new(new_resource.name)

      super

      if current_credentials
        @current_resource.api_key(current_credentials[:api_key])
      end

      @current_credentials
    end

    private

    def credentials_groovy
      <<-EOH.gsub(/ ^{8}/, '')
        import com.cloudbees.plugins.credentials.*
        import hudson.plugins.sauce_ondemand.credentials.SauceCredentials

        credentials = new SauceCredentials(
          CredentialsScope.GLOBAL,
          #{convert_to_groovy(new_resource.id)},
          #{convert_to_groovy(new_resource.username)},
          #{convert_to_groovy(new_resource.api_key)},
          #{convert_to_groovy(new_resource.description)}
        )
      EOH
    end

    def attribute_to_property_map
      { api_key: 'credentials.apiKey.plainText' }
    end
  end
end
