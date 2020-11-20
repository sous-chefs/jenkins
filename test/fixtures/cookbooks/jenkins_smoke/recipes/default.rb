include_recipe 'jenkins_server_wrapper::default'

#
# This recipe is a meta-collection of some common paths in the Jenkins cookbook.
# It should be run instead of the individual resource tests during trivial
# patches.
#
# This recipe will:
#
#   - Execute some basic commands
#   - Manage credentials (create)
#   - Manage jobs (create)
#   - Manage plugins (install)
#   - Execute some Groovy scripts
#   - Manage JNLP slaves (create)
#   - Manage SSH slaves (create)
#

#
# Authentication
# ------------------------------
include_recipe 'jenkins_authentication::private_key'

#
# Commands
# ------------------------------
include_recipe 'jenkins_command::execute'

#
# Credentials
# ------------------------------
include_recipe 'jenkins_credentials::default'

#
# Jobs
# ------------------------------
include_recipe 'jenkins_job::default'

#
# Plugins
# ------------------------------
include_recipe 'jenkins_plugin::default'

#
# Proxy
# ------------------------------
include_recipe 'jenkins_proxy::config'

#
# Script
# ------------------------------
include_recipe 'jenkins_script::execute'

#
# Slaves
# ------------------------------
include_recipe 'jenkins_slave::default'

#
# Users
# ------------------------------
include_recipe 'jenkins_user::default'

# The jenkins::_war_package recipe has a delayed restart on the jenkins service
# When Jenkins starts up, all slaves connect.
# We need to
# 1) wait for Jenkins to start
# 2) ensure the slave is disconnected after the service restart
ruby_block 'notify last things' do
  block do
    # no op
  end
  action :run

  notifies :run, 'ruby_block[wait for jenkins to start]', :delayed
end

ruby_block 'wait for jenkins to start' do
  block do
    begin
      response = Chef::HTTP.new(node['jenkins']['master']['endpoint']).get('/')

      raise 'Jenkins is starting up' if response.include?('Starting Jenkins')

      # After Jenkins has started the slaves will connect, but this can take some time
      # So we check that the expected slaves are online before running Inspec

      %w(
        jnlp-builder
        jnlp-executor
        ssh-builder
        ssh-executor
        ssh-smoke
        ssh-to-online
        ssh-to-connect
      ).each do |slave|
        body = Chef::HTTP.new(node['jenkins']['master']['endpoint']).get("/computer/#{slave}/api/json?pretty=true")
        json_body = JSON.parse(body, symbolize_names: true)

        raise "cannot find slave: #{slave}" unless json_body
        raise "slave: #{slave} isn't online" if json_body[:offline]
      end

      # Note:
      # Testing that slaves are connected and/or online is prone to failure
      # due to slow performance, different virtualization, etc
    rescue StandardError
      # re-raise exceptions so that the ruby_block triggers a retry
      raise
    end
  end

  retries 10
  retry_delay 30

  notifies :disconnect, 'jenkins_slave[disconnect ssh slave at the very end]', :delayed
end

jenkins_slave 'disconnect ssh slave at the very end' do
  slave_name 'ssh-to-disconnect'
  action :nothing
end
