#
# Cookbook Name:: jenkins
# Recipe:: default
#
# Author:: AJ Christensen <aj@junglist.gen.nz>
# Author:: Doug MacEachern <dougm@vmware.com>
# Author:: Fletcher Nichol <fnichol@nichol.ca>
# Author:: Seth Chisamore <schisamo@opscode.com>
#
# Copyright 2010, VMware, Inc.
# Copyright 2012, Opscode, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include_recipe "java"
include_recipe "runit"

user node['jenkins']['server']['user'] do
  home node['jenkins']['server']['home']
end

home_dir = node['jenkins']['server']['home']
data_dir = node['jenkins']['server']['data_dir']
plugins_dir = File.join(node['jenkins']['server']['data_dir'], "plugins")
log_dir = node['jenkins']['server']['log_dir']
ssh_dir = File.join(home_dir, ".ssh")
war_dir = File.join(home_dir, "war")

[
  home_dir,
  data_dir,
  plugins_dir,
  log_dir,
  ssh_dir,
  war_dir
].each do |dir_name|
  directory dir_name do
    owner node['jenkins']['server']['user']
    group node['jenkins']['server']['group']
    mode '0700'
    recursive true
  end
end

execute "ssh-keygen -f #{File.join(ssh_dir, "id_rsa")} -N ''" do
  user node['jenkins']['server']['user']
  group node['jenkins']['server']['group']
  not_if { File.exists?(File.join(ssh_dir, "id_rsa")) }
  notifies :create, "ruby_block[store_server_ssh_pubkey]", :immediately
end

ruby_block "store_server_ssh_pubkey" do
  block do
    node.set['jenkins']['server']['pubkey'] = IO.read(File.join(ssh_dir, "id_rsa.pub"))
  end
  action :nothing
end

ruby_block "block_until_operational" do
  block do
    Chef::Log.info "Waiting until Jenkins is listening on port #{node['jenkins']['server']['port']}"
    until JenkinsHelper.service_listening?(node['jenkins']['server']['port']) do
      sleep 1
      Chef::Log.debug(".")
    end

    Chef::Log.info "Waiting until the Jenkins API is responding"
    test_url = URI.parse("#{node['jenkins']['server']['url']}/api/json")
    until JenkinsHelper.endpoint_responding?(test_url) do
      sleep 1
      Chef::Log.debug(".")
    end
  end
  action :nothing
end

node['jenkins']['server']['plugins'].each do |plugin|
  version = 'latest'
  if plugin.is_a?(Hash)
    name = plugin['name']
    version = plugin['version'] if plugin['version']
  else
    name = plugin
  end

  # Plugins installed from the Jenkins Update Center are written to disk with
  # the `*.jpi` extension. Although plugins downloaded from the Jenkins Mirror
  # have an `*.hpi` extension we will save the plugins with a `*.jpi` extension
  # to match Update Center's behavior.
  remote_file File.join(plugins_dir, "#{name}.jpi") do
    source "#{node['jenkins']['mirror']}/plugins/#{name}/#{version}/#{name}.hpi"
    owner node['jenkins']['server']['user']
    group node['jenkins']['server']['group']
    backup false
    action :create_if_missing
    notifies :restart, "runit_service[jenkins]"
    notifies :create, "ruby_block[block_until_operational]"
  end
end

# download the specified version of Jenkins war file only if necessary

# if it is the latest, get the version number on the mirror website 
if node['jenkins']['server']['version'] == :latest
  chef_gem 'nokogiri'
  jenkins_version = JenkinsHelper.latest_version_number("#{node['jenkins']['mirror']}/war")
else
  jenkins_version = node['jenkins']['server']['version']
end

last_jenkins_war = File.join(war_dir,"jenkins_#{jenkins_version}.war")

unless File.exist?(last_jenkins_war)
  # clean the war_dir from older versions
  JenkinsHelper.delete_oldest_version(war_dir)

  # link the jenkins.war file to the last version
  link File.join(home_dir, "jenkins.war") do 
    to last_jenkins_war
    action :nothing
  end

  Chef::Log.info "Downloading the latest war file..."
  # Download the war file
  remote_file last_jenkins_war do
    source "#{node['jenkins']['mirror']}/war/#{jenkins_version}/jenkins.war"
    checksum node['jenkins']['server']['war_checksum'] unless node['jenkins']['server']['war_checksum'].nil?
    owner node['jenkins']['server']['user']
    group node['jenkins']['server']['group']
    notifies :restart, "runit_service[jenkins]"
    notifies :create, "link[#{File.join(home_dir, "jenkins.war")}]"
    notifies :create, "ruby_block[block_until_operational]"
  end

end

# Only restart if plugins were added
log "plugins updated, restarting jenkins" do
  only_if do
    # This file is touched on service start/restart
    pid_file = File.join(home_dir, "jenkins.start")
    if File.exists?(pid_file)
      htime = File.mtime(pid_file)
      Dir[File.join(plugins_dir, "*.hpi")].select { |file|
        File.mtime(file) > htime
      }.size > 0
    end
  end
  action :nothing
  notifies :restart, "runit_service[jenkins]"
  notifies :create, "ruby_block[block_until_operational]"
end

runit_service "jenkins"

log "ensure jenkins is running" do
  notifies :start, "runit_service[jenkins]", :immediately
  notifies :create, "ruby_block[block_until_operational]", :immediately
end
