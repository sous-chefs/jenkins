# Test Jenkins user and plugin management with security enabled
# This test verifies that CLI authentication works and we can manage users/plugins
include_recipe 'test::default'

# Admin credentials for CLI authentication
admin_username = 'chef'
admin_password = 'chefadmin123'

# Install mailer plugin (required by jenkins_user resource)
jenkins_plugin 'mailer'

# Ensure init.groovy.d directory exists (may not exist on WAR installations)
directory '/var/lib/jenkins/init.groovy.d' do
  owner 'jenkins'
  group 'jenkins'
  mode '0755'
  recursive true
end

# Create init script to set up security and admin user
# This runs on Jenkins startup and creates the admin user with password
file '/var/lib/jenkins/init.groovy.d/setup-security.groovy' do
  content <<-EOH
import jenkins.model.*
import hudson.model.*
import hudson.security.*

println("=== INIT SCRIPT: Setting up security ===")

def instance = Jenkins.getInstance()

// Set up security realm with signup disabled
println("=== INIT SCRIPT: Setting up HudsonPrivateSecurityRealm ===")
def realm = new HudsonPrivateSecurityRealm(false)
instance.setSecurityRealm(realm)

// Create admin user with password
println("=== INIT SCRIPT: Creating admin user '#{admin_username}' ===")
def adminUser = realm.createAccount("#{admin_username}", "#{admin_password}")
adminUser.setFullName('Chef Client')
adminUser.save()

// Use FullControlOnceLoggedInAuthorizationStrategy - allows authenticated users full control
// and anonymous users read access (needed for CLI to connect)
println("=== INIT SCRIPT: Setting up authorization strategy ===")
def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
strategy.setAllowAnonymousRead(true)
instance.setAuthorizationStrategy(strategy)

instance.save()
println("=== INIT SCRIPT: Security setup complete ===")
  EOH
  owner 'jenkins'
  group 'jenkins'
  mode '0644'
end

# Restart Jenkins to load plugins and run init script
execute 'reset systemd rate limit for plugins' do
  command 'systemctl reset-failed jenkins'
  action :run
end

execute 'restart jenkins for plugins' do
  command 'systemctl restart jenkins'
  action :run
end

# Wait for Jenkins to be ready (will return 200 with anonymous read, or 403 without)
ruby_block 'wait for jenkins after security setup' do
  block do
    require 'net/http'
    require 'uri'

    60.times do
      begin
        uri = URI.parse('http://localhost:8080/api/json')
        response = Net::HTTP.get_response(uri)
        break if response.code == '200' || response.code == '403'
      rescue StandardError => e
        Chef::Log.debug("Waiting for Jenkins: #{e.message}")
      end
      sleep 2
    end
  end
end

# Create credential file for CLI authentication
# This file contains username:password and is used by the CLI with -auth @file
file '/var/lib/jenkins/.cli-credentials' do
  content "#{admin_username}:#{admin_password}"
  owner 'jenkins'
  group 'jenkins'
  mode '0600'
  sensitive true
end

# Configure CLI to use the credential file
ruby_block 'configure cli authentication' do
  block do
    node.run_state[:jenkins_username] = admin_username
    node.run_state[:jenkins_password] = admin_password
  end
end

# Test CLI authentication by creating random-bob user
jenkins_script 'create random-bob user' do
  command <<-EOH.gsub(/^ {4}/, '')
    import hudson.model.User
    import hudson.security.HudsonPrivateSecurityRealm

    def realm = jenkins.model.Jenkins.getInstance().getSecurityRealm()
    if (realm instanceof HudsonPrivateSecurityRealm) {
      realm.createAccount("random-bob", "randompassword123")
      println("Created random-bob user")
    } else {
      println("Security realm is not HudsonPrivateSecurityRealm")
    }
  EOH
end

# Install greenballs plugin (tests that plugin installation works with auth)
jenkins_plugin 'greenballs'

# Restart Jenkins to load the greenballs plugin
execute 'reset systemd rate limit for greenballs' do
  command 'systemctl reset-failed jenkins'
  action :run
end

execute 'restart jenkins for greenballs' do
  command 'systemctl restart jenkins'
  action :run
end

# Wait for Jenkins to be ready after greenballs install
ruby_block 'wait for jenkins after greenballs' do
  block do
    require 'net/http'
    require 'uri'

    60.times do
      begin
        uri = URI.parse('http://localhost:8080/api/json')
        response = Net::HTTP.get_response(uri)
        break if response.code == '200' || response.code == '403'
      rescue StandardError => e
        Chef::Log.debug("Waiting for Jenkins: #{e.message}")
      end
      sleep 2
    end
  end
end

# Create users.xml mapping file for InSpec tests
# This needs to run after Jenkins has created the user directories
jenkins_script 'create users.xml mapping' do
  command <<-EOH.gsub(/^ {4}/, '')
    import jenkins.model.Jenkins

    def instance = Jenkins.getInstance()
    def usersDir = new File(instance.getRootDir(), "users")
    def usersXml = new File(usersDir, "users.xml")

    // Find the actual directory names for each user
    def chefDir = usersDir.listFiles()?.find { it.name.startsWith('chef_') }?.name ?: 'chef'
    def bobDir = usersDir.listFiles()?.find { it.name.startsWith('random-bob_') || it.name.startsWith('randombob_') }?.name ?: 'random-bob'

    def xmlContent = """<?xml version='1.1' encoding='UTF-8'?>
<hudson.model.UserIdMapper>
  <version>1</version>
  <idToDirectoryNameMap class="concurrent-hash-map">
    <entry>
      <string>chef</string>
      <string>${chefDir}</string>
    </entry>
    <entry>
      <string>random-bob</string>
      <string>${bobDir}</string>
    </entry>
  </idToDirectoryNameMap>
</hudson.model.UserIdMapper>
"""
    usersXml.text = xmlContent
    println("Created users.xml mapping file")
  EOH
end
