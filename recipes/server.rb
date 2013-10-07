#
# Author:: AJ Christensen <aj@junglist.gen.nz>
# Author:: Dough MacEachern <dougm@vmware.com>
# Author:: Fletcher Nichol <fnichol@nichol.ca>
# Author:: Seth Chisamore <schisamo@opscode.com>
# Author:: Guilhem Lettron <guilhem.lettron@youscribe.com>
#
# Cookbook Name:: jenkins
# Recipe:: server
#
# Copyright 2010, VMWare, Inc.
# Copyright 2012, Opscode, Inc.
# Copyright 2013, Youscribe.
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

include_recipe 'java::default'

user node['jenkins']['server']['user'] do
  home node['jenkins']['server']['home']
end

home_dir = node['jenkins']['server']['home']
plugins_dir = File.join(home_dir, 'plugins')
log_dir = node['jenkins']['server']['log_dir']
ssh_dir = File.join(home_dir, '.ssh')

directory home_dir do
  owner node['jenkins']['server']['user']
  group node['jenkins']['server']['home_dir_group']
  mode node['jenkins']['server']['dir_permissions']
  recursive true
end

directory plugins_dir do
  owner node['jenkins']['server']['user']
  group node['jenkins']['server']['plugins_dir_group']
  mode node['jenkins']['server']['dir_permissions']
  recursive true
end

directory log_dir do
  owner node['jenkins']['server']['user']
  group node['jenkins']['server']['log_dir_group']
  mode node['jenkins']['server']['log_dir_permissions']
  recursive true
end

directory ssh_dir do
  owner node['jenkins']['server']['user']
  group node['jenkins']['server']['ssh_dir_group']
  mode node['jenkins']['server']['ssh_dir_permissions']
  recursive true
end

include_recipe "jenkins::_server_#{node['jenkins']['server']['install_method']}"

execute "ssh-keygen -f #{File.join(ssh_dir, "id_rsa")} -N ''" do
  user node['jenkins']['server']['user']
  group node['jenkins']['server']['ssh_dir_group']
  not_if { File.exists?(File.join(ssh_dir, 'id_rsa')) }
  notifies :create, 'ruby_block[store_server_ssh_pubkey]', :immediately
end

ruby_block 'store_server_ssh_pubkey' do
  block do
    node.set['jenkins']['server']['pubkey'] = IO.read(File.join(ssh_dir, 'id_rsa.pub'))
    node.save unless Chef::Config[:solo]
  end
  action :nothing
end

node['jenkins']['server']['plugins'].each do |plugin|
  if plugin.is_a?(Hash)
    name = plugin['name']
    version = plugin['version'] if plugin['version']
    url = plugin['url'] if plugin['url']
  else
    name = plugin
  end

  jenkins_plugin name do
    action  :install
    version version if version
    url     url if url
  end
end

ruby_block 'block_until_operational' do
  block do
    Chef::Log.info "Waiting until Jenkins is listening on port #{node['jenkins']['server']['port']}"
    until JenkinsHelper.service_listening?(node['jenkins']['server']['port'])
      sleep 1
      Chef::Log.debug('.')
    end

    Chef::Log.info 'Waiting until the Jenkins API is responding'
    test_url = URI.parse("#{node['jenkins']['server']['url']}/api/json")
    until JenkinsHelper.endpoint_responding?(test_url)
      sleep 1
      Chef::Log.debug('.')
    end
  end
  action :nothing
end

log 'ensure_jenkins_is_running' do
  notifies :start, 'service[jenkins]', :immediately
  notifies :create, 'ruby_block[block_until_operational]', :immediately
end
