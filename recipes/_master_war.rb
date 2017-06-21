#
# Cookbook:: jenkins
# Recipe:: _master_war
#
# Author: AJ Christensen <aj@junglist.gen.nz>
# Author: Doug MacEachern <dougm@vmware.com>
# Author: Fletcher Nichol <fnichol@nichol.ca>
# Author: Seth Chisamore <schisamo@chef.io>
# Author: Seth Vargo <sethvargo@gmail.com>
# Author: Drew Budwin <dbudwin@foxguardsolutions.com>
#
# Copyright:: 2010-2016, VMware, Inc.
# Copyright:: 2012-2016, Chef Software, Inc.
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

# Create the Jenkins user
user node['jenkins']['master']['user'] do
  home node['jenkins']['master']['home']
  system node['jenkins']['master']['use_system_accounts'] # ~FC048
end

# Create the Jenkins group
group node['jenkins']['master']['group'] do
  members node['jenkins']['master']['user']
  system node['jenkins']['master']['use_system_accounts'] # ~FC048
end

# Create the home directory
directory node['jenkins']['master']['home'] do
  owner     node['jenkins']['master']['user']
  group     node['jenkins']['master']['group']
  mode      '0755'
  recursive true
end

# Create the log directory
directory node['jenkins']['master']['log_directory'] do
  owner     node['jenkins']['master']['user']
  group     node['jenkins']['master']['group']
  mode      '0755'
  recursive true
end

# Download the remote WAR file
remote_file File.join(node['jenkins']['master']['home'], 'jenkins.war') do
  source   node['jenkins']['master']['source']
  checksum node['jenkins']['master']['checksum'] if node['jenkins']['master']['checksum']
  owner    node['jenkins']['master']['user']
  group    node['jenkins']['master']['group']
  notifies :restart, 'service[jenkins]'
end

directory "#{node['jenkins']['master']['home']}/tmp" do
  owner     node['jenkins']['master']['user']
  group     node['jenkins']['master']['group']
  mode      '0755'
  recursive true
end

template '/lib/systemd/system/jenkins.service' do
  source 'jenkins.service.erb'
  owner  'root'
  group  'root'
  mode   '0644'
  action :create
end

case node['platform_family']
when 'debian'
  template   '/etc/default/jenkins' do
    source   'jenkins-config-debian.erb'
    mode     '0644'
    notifies :restart, 'service[jenkins]', :immediately
  end
when 'rhel'
  template   '/etc/sysconfig/jenkins' do
    source   'jenkins-config-rhel.erb'
    mode     '0644'
    notifies :restart, 'service[jenkins]', :immediately
  end
end

service 'jenkins' do
  supports status: true, restart: true, reload: true
  action [:enable, :start]
end
