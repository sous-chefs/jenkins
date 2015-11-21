include_recipe 'jenkins_server_wrapper::default'

#
# Setup
# ------------------------------

# Load the private key from a data bag item. This should be an encrypted data
# bag item in real deployments.
jenkins = data_bag_item('keys', 'jenkins')

require 'openssl'
require 'net/ssh'
key = OpenSSL::PKey::RSA.new(jenkins['private_key'])
private_key = key.to_pem
public_key  = "#{key.ssh_type} #{[key.to_blob].pack('m0')}"

# Set the private key on the executor
node.run_state[:jenkins_private_key] = private_key

# Create a default Chef user with the public key
jenkins_user 'chef' do
  full_name   'Chef Client'
  public_keys [public_key]
end

# Turn on basic authentication
jenkins_script 'setup authentication' do
  command <<-EOH.gsub(/^ {4}/, '')
    import jenkins.model.*
    def instance = Jenkins.getInstance()

    import hudson.security.*
    def realm = new HudsonPrivateSecurityRealm(false)
    instance.setSecurityRealm(realm)

    def strategy = new hudson.security.FullControlOnceLoggedInAuthorizationStrategy()
    instance.setAuthorizationStrategy(strategy)

    instance.save()
  EOH
end

# Run some commands - this will ensure the CLI is correctly passing attributes
jenkins_command 'clear-queue'

# Install a plugin
jenkins_plugin 'greenballs' do
  notifies :restart, 'service[jenkins]', :immediately
end

# Try creating another user
jenkins_user 'random-bob'
