#
# Cookbook:: jenkins
# Library:: credentials_helpers
#
# Helper module for credentials custom resources
#

require 'json'
require 'openssl'
require 'securerandom'

module Jenkins
  module CredentialsHelpers
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

    #
    # Helper to fetch credentials for a given ID
    #
    def credentials_for_id_groovy(id, groovy_variable_name)
      <<-EOH.gsub(/^ {8}/, '')
        #{groovy_variable_name} = com.cloudbees.plugins.credentials.CredentialsProvider.lookupCredentials(
          com.cloudbees.plugins.credentials.Credentials.class,
          Jenkins.instance,
          null,
          null
        ).find { it.id == #{convert_to_groovy(id)} }
      EOH
    end
  end
end
