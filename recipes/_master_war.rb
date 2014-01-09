#
# Cookbook Name:: jenkins
# Recipe:: _master_war
#
# Author: AJ Christensen <aj@junglist.gen.nz>
# Author: Doug MacEachern <dougm@vmware.com>
# Author: Fletcher Nichol <fnichol@nichol.ca>
# Author: Seth Chisamore <schisamo@getchef.com>
# Author: Seth Vargo <sethvargo@gmail.com>
#
# Copyright 2010, VMware, Inc.
# Copyright 2012-2014, Chef Software, Inc.
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

# Include runit to setup the service
include_recipe 'runit::default'

# Download the remote WAR file
remote_file File.join(node['jenkins']['master']['home'], 'jenkins.war') do
  source   node['jenkins']['master']['source']
  checksum node['jenkins']['master']['checksum'] if node['jenkins']['master']['checksum']
  owner    node['jenkins']['master']['user']
  group    node['jenkins']['master']['group']
  notifies :restart, 'service[jenkins]'
end

# Create runit service
runit_service 'jenkins'
