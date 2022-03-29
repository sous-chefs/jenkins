require 'json'
require 'openssl'
require 'securerandom'

property :id,
          String,
          required: true

def load_current_resource
  @current_resource ||= Resource::JenkinsCredentials.new(new_resource.name)

  if current_credentials
    @current_resource.exists = true
    @current_resource.id(current_credentials[:id])
    @current_resource.description(current_credentials[:description])
  end

  @current_resource
end

action :create do
  if current_resource.exists? && correct_config?
    Chef::Log.info("#{new_resource} exists - skipping")
  else
    converge_by("Create #{new_resource}") do
      executor.groovy! <<-EOH.gsub(/^ {12}/, '')
        import jenkins.model.*
        import com.cloudbees.plugins.credentials.*
        import com.cloudbees.plugins.credentials.domains.*
        import hudson.plugins.sshslaves.*;

        global_domain = Domain.global()
        credentials_store =
          Jenkins.instance.getExtensionList(
            'com.cloudbees.plugins.credentials.SystemCredentialsProvider'
          )[0].getStore()

        #{credentials_groovy}

        #{fetch_existing_credentials_groovy('existing_credentials')}

        if(existing_credentials != null) {
          credentials_store.updateCredentials(
            global_domain,
            existing_credentials,
            credentials
          )
        } else {
          credentials_store.addCredentials(global_domain, credentials)
        }
      EOH
    end
  end
end

action :delete do
  if current_resource.exists?
    converge_by("Delete #{new_resource}") do
      executor.groovy! <<-EOH.gsub(/^ {12}/, '')
        import jenkins.model.*
        import com.cloudbees.plugins.credentials.*;

        global_domain = com.cloudbees.plugins.credentials.domains.Domain.global()
        credentials_store =
          Jenkins.instance.getExtensionList(
            'com.cloudbees.plugins.credentials.SystemCredentialsProvider'
          )[0].getStore()

        #{fetch_existing_credentials_groovy('existing_credentials')}

        if(existing_credentials != null) {
          credentials_store.removeCredentials(
            global_domain,
            existing_credentials
          )
        }
      EOH
    end
  else
    Chef::Log.debug("#{new_resource} does not exist - skipping")
  end
end

action_class do
  #
  # Returns a Groovy snippet that creates an instance of the
  # credential's implementation. The credentials instance should be
  # set to a Groovy variable named `credentials`.
  #
  # @abstract
  # @return [String]
  #
  def credentials_groovy
    raise NotImplementedError, 'You must implement #credentials_groovy.'
  end

  #
  # Returns a Groovy snippet that fetches credentials from the
  # credentials store. The snippet relies on the existence of both
  # 'credentials_store' and 'credentials' variables, representing the
  # Jenkins credentials store and the credentials to be fetched, respectively
  # @abstract
  # @return [String]
  #
  def fetch_existing_credentials_groovy(_groovy_variable_name)
    raise NotImplementedError, 'You must implement #fetch_existing_credentials_groovy.'
  end

  #
  # Returns a Groovy snippet with an array of the resource attributes. The snippet
  # relies on the existence of a variable credentials that represents the resource
  # @abstract
  # @return [String]
  #
  def resource_attributes_groovy(_groovy_variable_name)
    raise NotImplementedError, 'You must implement #resource_attributes_groovy.'
  end

  #
  # Helper method for determining if the given JSON is in sync with the
  # current configuration on the Jenkins instance.
  #
  # @return [Boolean]
  #
  def correct_config?
    raise NotImplementedError, 'You must implement #correct_config?.'
  end

  #
  # Maps a credentials's resource attribute name to the equivalent
  # property in the Groovy representation. This mapping is useful in
  # Ruby/Groovy serialization/deserialization.
  #
  # @return [Hash]
  #
  # @example
  #   {password: 'credentials.password.plainText'}
  #
  def attribute_to_property_map
    {}
  end

  #
  # Loads the current credential into a Hash.
  #
  def current_credentials
    return @current_credentials if @current_credentials

    Chef::Log.debug "Load #{new_resource} credentials information"

    credentials_attributes = []
    attribute_to_property_map.each_pair do |resource_attribute, groovy_property|
      credentials_attributes <<
        "current_credentials['#{resource_attribute}'] = #{groovy_property}"
    end

    json = executor.groovy! <<-EOH.gsub(/^ {8}/, '')
      import com.cloudbees.plugins.credentials.impl.*;
      import com.cloudbees.jenkins.plugins.sshcredentials.impl.*;

      #{fetch_existing_credentials_groovy('credentials')}

      if(credentials == null) {
        return null
      }

      #{resource_attributes_groovy('current_credentials')}

      #{credentials_attributes.join("\n")}

      builder = new groovy.json.JsonBuilder(current_credentials)
      println(builder)
    EOH

    return if json.nil? || json.empty?

    @current_credentials = JSON.parse(json, symbolize_names: true)

    # Values that were serialized as nil/null are deserialized as an
    # empty string! :( Let's ensure we convert back to nil.
    @current_credentials = convert_blank_values_to_nil(@current_credentials)
  end
end
