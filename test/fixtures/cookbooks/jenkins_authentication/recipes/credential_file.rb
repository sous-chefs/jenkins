shadow_group = platform_family?('debian') ? 'shadow' : 'root'

include_recipe 'jenkins_server_wrapper::default'

#
# Setup
# ------------------------------

# Ensure the `jenkins` can access /etc/shadow

group shadow_group do
  append true
  members %w(jenkins)
  notifies :restart, 'service[jenkins]', :immediately
end

# RHEL uses 000 for /etc/shadow by default so we need to at least make it group readable
file '/etc/shadow' do
  mode '040'
  notifies :restart, 'service[jenkins]', :immediately
end if platform_family?('rhel', 'amazon')

user 'vagrant' do
  manage_home true
  password '$6$a8wKXl8H$BWxzd2KvIgAFdZAdM5IDGCaDY8fL5DZ30GKzGyblFG8A/XSlpL1OiWrUg2BQpMvNE2gzgwUZRpBPUWHpJZstx.'
end

# Set up the auth file on the executor. You should pull the content from
# a secret store or encrypted data bag item.
cred_file = '/etc/cli_cred_file'
file cred_file do
  content 'vagrant:vagrant'
  owner 'jenkins'
  group 'root'
  mode '0444'
  action :create
end
node.default[:jenkins][:executor][:cli_credential_file] = cred_file


jenkins_plugin 'pam-auth' do
  notifies :restart, 'service[jenkins]', :immediately
end

package 'openssh-server'

# Turn on basic authentication
jenkins_script 'setup authentication' do
  command <<-EOH.gsub(/^ {4}/, '')
    import jenkins.model.*
    def instance = Jenkins.getInstance()

    import hudson.security.*
    def realm = new PAMSecurityRealm("sshd")
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
