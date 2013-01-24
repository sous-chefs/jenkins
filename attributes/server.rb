#
# Cookbook Name:: jenkins
# Attributes:: server
#
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

default['jenkins']['server']['home']     = "/var/lib/jenkins"
default['jenkins']['server']['data_dir'] = File.join(node['jenkins']['server']['home'], "jenkins-data")
default['jenkins']['server']['log_dir']  = "/var/log/jenkins"

default['jenkins']['server']['user'] = "jenkins"
case node['platform_family']
when "debian"
  default['jenkins']['server']['group'] = "nogroup"
else
  default['jenkins']['server']['group'] = node['jenkins']['server']['user']
end

default['jenkins']['server']['version'] = :latest
default['jenkins']['server']['war_checksum'] = nil

default['jenkins']['server']['port'] = 8080
default['jenkins']['server']['host'] = node['fqdn']
default['jenkins']['server']['url']  = "http://#{node['jenkins']['server']['host']}:#{node['jenkins']['server']['port']}"

default['jenkins']['server']['plugins'] = []
default['jenkins']['server']['jvm_options'] = nil

default['jenkins']['http_proxy']['variant']              = nil
default['jenkins']['http_proxy']['www_redirect']         = "disable"
default['jenkins']['http_proxy']['listen_ports']         = [ 80 ]
default['jenkins']['http_proxy']['host_name']            = nil
default['jenkins']['http_proxy']['host_aliases']         = []
default['jenkins']['http_proxy']['client_max_body_size'] = "1024m"
default['jenkins']['http_proxy']['basic_auth_username'] = "jenkins"
default['jenkins']['http_proxy']['basic_auth_password'] = "jenkins"
