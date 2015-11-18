include_recipe 'jenkins_server_wrapper::default'

#
# Setup
# ------------------------------

# Ensure the `jenkins` user is part of the `shadow` group
group 'shadow' do
  append true
  members %w(jenkins)
  notifies :restart, 'service[jenkins]', :immediately
end

# Set the username/password on the executor. You should pull these from
# a secret store or encrypted data bag item.
node.run_state[:jenkins_username] = 'vagrant'
node.run_state[:jenkins_password] = 'vagrant'

# Turn on basic authentication
jenkins_script 'setup authentication' do
  command <<-EOH.gsub(/^ {4}/, '')
    import jenkins.model.*
    def instance = Jenkins.getInstance()

    import hudson.security.*
    def realm = new PAMSecurityRealm(null)
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
