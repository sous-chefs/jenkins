require 'json'
require 'openssl'

unified_mode true

resource_name :jenkins_private_key_credentials
provides :jenkins_private_key_credentials

property :id, String, required: true
property :username, String, name_property: true
property :private_key, [String, OpenSSL::PKey::RSA, OpenSSL::PKey::EC], required: true, sensitive: true
property :passphrase, String, sensitive: true
property :description, String,
         default: lazy { |r| "Credentials for #{r.username} - created by Chef" }

# Mark resource as sensitive by default
def initialize(name, run_context = nil)
  super
  @sensitive = true
end

load_current_value do
  current_creds = current_credentials_from_jenkins

  if current_creds
    id current_creds[:id]
    description current_creds[:description]
    username current_creds[:username]
    private_key current_creds[:private_key] if current_creds[:private_key]
    passphrase current_creds[:passphrase] if current_creds[:passphrase]
  else
    current_value_does_not_exist!
  end
end

action :create do
  if current_resource && correct_config?
    Chef::Log.info("#{new_resource} exists - skipping")
  else
    converge_by("Create #{new_resource}") do
      executor.groovy! <<-EOH.gsub(/^ {8}/, '')
        import jenkins.model.*
        import com.cloudbees.plugins.credentials.*
        import com.cloudbees.plugins.credentials.domains.*
        import com.cloudbees.jenkins.plugins.sshcredentials.impl.*

        global_domain = Domain.global()
        credentials_store =
          Jenkins.instance.getExtensionList(
            'com.cloudbees.plugins.credentials.SystemCredentialsProvider'
          )[0].getStore()

        private_key = """#{pem_private_key}
        """

        credentials = new BasicSSHUserPrivateKey(
          CredentialsScope.GLOBAL,
          #{convert_to_groovy(new_resource.id)},
          #{convert_to_groovy(new_resource.username)},
          new BasicSSHUserPrivateKey.DirectEntryPrivateKeySource(private_key),
          #{convert_to_groovy(new_resource.passphrase)},
          #{convert_to_groovy(new_resource.description)}
        )

        #{credentials_for_id_groovy(new_resource.id, 'existing_credentials')}

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
  if current_resource
    converge_by("Delete #{new_resource}") do
      executor.groovy! <<-EOH.gsub(/^ {8}/, '')
        import jenkins.model.*
        import com.cloudbees.plugins.credentials.*;

        global_domain = com.cloudbees.plugins.credentials.domains.Domain.global()
        credentials_store =
          Jenkins.instance.getExtensionList(
            'com.cloudbees.plugins.credentials.SystemCredentialsProvider'
          )[0].getStore()

        #{credentials_for_id_groovy(new_resource.id, 'existing_credentials')}

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
    if new_resource.private_key.is_a?(OpenSSL::PKey::RSA) || new_resource.private_key.is_a?(OpenSSL::PKey::EC)
      new_resource.private_key.to_pem
    elsif ecdsa_key?(new_resource.private_key)
      OpenSSL::PKey::EC.new(new_resource.private_key).to_pem
    else
      OpenSSL::PKey::RSA.new(new_resource.private_key).to_pem
    end
  end

  def current_credentials_from_jenkins
    return @current_credentials if @current_credentials

    Chef::Log.debug "Load #{new_resource} credentials information"

    json = executor.groovy! <<-EOH.gsub(/^ {6}/, '')
      import com.cloudbees.jenkins.plugins.sshcredentials.impl.*;

      #{credentials_for_id_groovy(new_resource.id, 'credentials')}

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

  def correct_config?
    wanted_credentials = {
      description: new_resource.description,
      username: new_resource.username,
      private_key: pem_private_key.is_a?(OpenSSL::PKey::RSA) || pem_private_key.is_a?(OpenSSL::PKey::EC) ? pem_private_key.to_pem : pem_private_key,
      passphrase: new_resource.passphrase,
    }

    # Normalize current private key for comparison
    current = current_credentials_from_jenkins.dup
    if current[:private_key]
      current[:private_key] = current[:private_key].to_pem if current[:private_key].is_a?(OpenSSL::PKey::RSA) || current[:private_key].is_a?(OpenSSL::PKey::EC)
    end

    # Don't compare the ID as it is generated
    current.tap { |c| c.delete(:id) } == convert_blank_values_to_nil(wanted_credentials)
  end

  def credentials_for_id_groovy(id, groovy_variable_name)
    <<-EOH.gsub(/^ {6}/, '')
      #{groovy_variable_name} = com.cloudbees.plugins.credentials.CredentialsProvider.lookupCredentials(
        com.cloudbees.plugins.credentials.Credentials.class,
        Jenkins.instance,
        null,
        null
      ).find { it.id == #{convert_to_groovy(id)} }
    EOH
  end
end
