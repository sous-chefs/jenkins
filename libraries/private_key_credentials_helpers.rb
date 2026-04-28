#
# Cookbook:: jenkins
# Library:: private_key_credentials_helpers
#

require_relative '_helper'
require_relative 'credentials_helpers'

module Jenkins
  module PrivateKeyCredentialsHelpers
    include Jenkins::Helper
    include Jenkins::CredentialsHelpers

    #
    # Determine whether a key is an ECDSA key.
    #
    def ecdsa_key?(key)
      key.include?('BEGIN EC PRIVATE KEY')
    end

    #
    # Private key in PEM format
    #
    def pem_private_key
      resource = credentials_resource

      if resource.private_key.is_a?(OpenSSL::PKey::RSA) || resource.private_key.is_a?(OpenSSL::PKey::EC)
        resource.private_key.to_pem
      elsif ecdsa_key?(resource.private_key)
        OpenSSL::PKey::EC.new(resource.private_key).to_pem
      else
        OpenSSL::PKey::RSA.new(resource.private_key).to_pem
      end
    end

    def current_credentials_from_jenkins(resource = credentials_resource)
      return @current_credentials if @current_credentials

      Chef::Log.debug "Load #{resource} credentials information"

      json = executor.groovy! <<-EOH.gsub(/^ {6}/, '')
        import com.cloudbees.jenkins.plugins.sshcredentials.impl.*;

        #{credentials_for_id_groovy(resource.id, 'credentials')}

        if(credentials == null) {
          return null
        }

        current_credentials = [
          id:credentials.id,
          description:credentials.description,
          username:credentials.username
        ]

        current_credentials['private_key'] = credentials.privateKey
        current_credentials['passphrase'] = credentials.passphrase && credentials.passphrase.plainText

        builder = new groovy.json.JsonBuilder(current_credentials)
        println(builder)
      EOH

      return if json.nil? || json.empty?

      @current_credentials = JSON.parse(json, symbolize_names: true)
      @current_credentials = convert_blank_values_to_nil(@current_credentials)

      # Normalize the private key
      if @current_credentials && @current_credentials[:private_key]
        cc = @current_credentials[:private_key]
        cc = @current_credentials[:private_key].to_pem unless cc.is_a?(String)
        @current_credentials[:private_key] = ecdsa_key?(cc) ? OpenSSL::PKey::EC.new(cc) : OpenSSL::PKey::RSA.new(cc)
      end

      @current_credentials
    end

    private

    def credentials_resource
      respond_to?(:new_resource) && new_resource ? new_resource : self
    end
  end
end
