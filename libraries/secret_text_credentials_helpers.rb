#
# Cookbook:: jenkins
# Library:: secret_text_credentials_helpers
#

require_relative '_helper'
require_relative 'credentials_helpers'

module Jenkins
  module SecretTextCredentialsHelpers
    include Jenkins::Helper
    include Jenkins::CredentialsHelpers

    def current_credentials_from_jenkins(resource = credentials_resource)
      return @current_credentials if @current_credentials

      Chef::Log.debug "Load #{resource} credentials information"

      json = executor.groovy! <<-EOH.gsub(/^ {6}/, '')
        import org.jenkinsci.plugins.plaincredentials.impl.*;

        #{credentials_for_id_groovy(resource.id, 'credentials')}

        if(credentials == null) {
          return null
        }

        current_credentials = [
          id:credentials.id,
          description:credentials.description,
          secret:credentials.secret
        ]

        current_credentials['secret'] = credentials.secret.plainText

        builder = new groovy.json.JsonBuilder(current_credentials)
        println(builder)
      EOH

      return if json.nil? || json.empty?

      @current_credentials = JSON.parse(json, symbolize_names: true)
      @current_credentials = convert_blank_values_to_nil(@current_credentials)
    end

    private

    def credentials_resource
      respond_to?(:new_resource) && new_resource ? new_resource : self
    end
  end
end
