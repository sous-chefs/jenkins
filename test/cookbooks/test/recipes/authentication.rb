# Test authentication with private key
include_recipe 'test::default'

# Load keys from data bag
jenkins_keys = data_bag_item('keys', 'jenkins')
private_key = jenkins_keys['private_key']
public_key = jenkins_keys['public_key']

# Set private key IMMEDIATELY before any CLI operations
# This ensures the key file is written correctly
node.run_state[:jenkins_private_key] = private_key
node.run_state[:jenkins_private_key_path] = nil  # Clear any cached path

# Debug: verify key is set
ruby_block 'verify key before init script' do
  block do
    Chef::Log.warn("=== DEBUG: Private key length: #{private_key.length}")
    Chef::Log.warn("=== DEBUG: Private key starts with: #{private_key[0..50]}")
    Chef::Log.warn("=== DEBUG: Public key: #{public_key[0..50]}...")
  end
end

# Create init script to set up user and security on Jenkins startup
# This avoids the chicken-and-egg problem with CLI authentication
file '/var/lib/jenkins/init.groovy.d/setup-auth.groovy' do
  content <<-EOH
import jenkins.model.*
import hudson.model.*
import hudson.security.*
import org.jenkinsci.main.modules.cli.auth.ssh.UserPropertyImpl

println("=== INIT SCRIPT: Starting authentication setup ===")

def instance = Jenkins.getInstance()

// Create chef user with SSH key
println("=== INIT SCRIPT: Creating user 'chef' ===")
def user = User.get('chef')
user.setFullName('Chef Client')

println("=== INIT SCRIPT: Adding SSH public key ===")
def keys = new UserPropertyImpl('#{public_key}')
user.addProperty(keys)
user.save()
println("=== INIT SCRIPT: User 'chef' saved with SSH key ===")

// Set up security realm
println("=== INIT SCRIPT: Setting up security realm ===")
def realm = new HudsonPrivateSecurityRealm(false)
instance.setSecurityRealm(realm)

// Grant permissions
println("=== INIT SCRIPT: Setting up authorization strategy ===")
def strategy = new GlobalMatrixAuthorizationStrategy()
strategy.add(Jenkins.ADMINISTER, "chef")
strategy.add(Jenkins.READ, "anonymous")
instance.setAuthorizationStrategy(strategy)

instance.save()
println("=== INIT SCRIPT: Authentication setup complete ===")
  EOH
  owner 'jenkins'
  group 'jenkins'
  mode '0644'
end

# Restart Jenkins to apply init script
execute 'restart jenkins for auth setup' do
  command 'systemctl restart jenkins'
  action :run
end

# Wait for Jenkins to be ready
ruby_block 'wait for jenkins after auth setup' do
  block do
    require 'net/http'
    require 'uri'
    
    30.times do
      begin
        uri = URI.parse('http://localhost:8080/api/json')
        response = Net::HTTP.get_response(uri)
        break if response.code == '200' || response.code == '403'
      rescue
        # Not ready yet
      end
      sleep 2
    end
  end
end

# Debug: check what's in the key file
ruby_block 'check key file' do
  block do
    key_file = '/opt/kitchen/cache/jenkins-key'
    if File.exist?(key_file)
      content = File.read(key_file)
      Chef::Log.warn("=== DEBUG: Key file exists, length: #{content.length}")
      Chef::Log.warn("=== DEBUG: Key file starts with: #{content[0..50]}")
    else
      Chef::Log.warn("=== DEBUG: Key file does NOT exist!")
    end
  end
end

# Test that CLI authentication works with the key
jenkins_script 'test cli authentication' do
  command <<-EOH.gsub(/^ {4}/, '')
    println("CLI authentication successful with user: " + hudson.model.User.current().getId())
  EOH
end
