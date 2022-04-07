unified_mode true

# require_relative 'credentials'
# require_relative 'credentials_user'

include Jenkins::Helper

resource_name :jenkins_private_key_credentials # Still needed for Chef 15 and below
provides :jenkins_private_key_credentials

# Attributes
property :username,
          String,
          name_property: true
property :private_key,
          [String, OpenSSL::PKey::RSA, OpenSSL::PKey::EC],
          required: true
property :passphrase,
          String

def load_current_resource
  @current_resource ||= Resource::JenkinsPrivateKeyCredentials.new(new_resource.name)

  super

  @current_resource.private_key(current_credentials[:private_key]) if current_credentials

  @current_resource
end

action_class do
  #
  # @see Chef::Resource::JenkinsCredentials#credentials_groovy
  # @see https://github.com/jenkinsci/ssh-credentials-plugin/blob/master/src/main/java/com/cloudbees/jenkins/plugins/sshcredentials/impl/BasicSSHUserPrivateKey.java
  #
  def credentials_groovy
    <<-EOH.gsub(/^ {8}/, '')
      import com.cloudbees.plugins.credentials.*
      import com.cloudbees.jenkins.plugins.sshcredentials.impl.*

      private_key = """#{new_resource.pem_private_key}
      """

      credentials = new BasicSSHUserPrivateKey(
        CredentialsScope.GLOBAL,
        #{convert_to_groovy(new_resource.id)},
        #{convert_to_groovy(new_resource.username)},
        new BasicSSHUserPrivateKey.DirectEntryPrivateKeySource(private_key),
        #{convert_to_groovy(new_resource.passphrase)},
        #{convert_to_groovy(new_resource.description)}
      )
    EOH
  end

  #
  # @see Chef::Resource::JenkinsCredentials#attribute_to_property_map
  #
  def attribute_to_property_map
    {
      private_key: 'credentials.privateKey',
      passphrase: 'credentials.passphrase && credentials.passphrase.plainText',
    }
  end

  #
  # @see Chef::Resource::JenkinsCredentials#current_credentials
  #
  def current_credentials
    super

    # Normalize the private key
    if @current_credentials && @current_credentials[:private_key]
      cc = @current_credentials[:private_key]
      cc = @current_credentials[:private_key].to_pem unless cc.is_a?(String)
      @current_credentials[:private_key] = ecdsa_key?(cc) ? OpenSSL::PKey::EC.new(cc) : OpenSSL::PKey::RSA.new(cc)
    end

    @current_credentials
  end

  #
  # Determine whether a key is an ECDSA key. As original functionality
  # assumed that exclusively RSA keys were used, not breaking this assumption
  # despite ECDSA keys being a possibility alleviates some issues with
  # backwards-compatibility.
  #
  # @param [String] key
  # @return [TrueClass, FalseClass]
  def ecdsa_key?(key)
    key.include?('BEGIN EC PRIVATE KEY')
  end

  #
  # Private key of the credentials . This should be the actual key
  # contents (as opposed to the path to a private key file) in OpenSSH
  # format.
  #
  # @param [String] arg
  # @return [String]
  #
  def pem_private_key
    if private_key.is_a?(OpenSSL::PKey::RSA) || private_key.is_a?(OpenSSL::PKey::EC)
      private_key.to_pem
    elsif ecdsa_key?(private_key)
      OpenSSL::PKey::EC.new(private_key).to_pem
    else
      OpenSSL::PKey::RSA.new(private_key).to_pem
    end
  end
end
