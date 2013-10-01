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

default['jenkins']['server']['home'] = '/var/lib/jenkins'
default['jenkins']['server']['log_dir'] = '/var/log/jenkins'

default['jenkins']['server']['user'] = 'jenkins'
case node['platform_family']
when 'debian'
  default['jenkins']['server']['install_method'] = 'package'
  default['jenkins']['server']['group'] = 'nogroup'
  default['jenkins']['server']['config_path'] = '/etc/default/jenkins'
  default['jenkins']['server']['config_template'] = 'default.erb'
when 'rhel'
  default['jenkins']['server']['install_method'] = 'package'
  default['jenkins']['server']['group'] = default['jenkins']['server']['user']
  default['jenkins']['server']['config_path'] = '/etc/sysconfig/jenkins'
  default['jenkins']['server']['config_template'] = 'sysconfig.erb'
else
  default['jenkins']['server']['install_method'] = 'war'
  default['jenkins']['server']['group'] = default['jenkins']['server']['user']
end

default['jenkins']['server']['version'] = nil
default['jenkins']['server']['war_checksum'] = nil

default['jenkins']['server']['port'] = 8080
default['jenkins']['server']['host'] = node['fqdn']
default['jenkins']['server']['url']  = "http://#{default['jenkins']['server']['host']}:#{default['jenkins']['server']['port']}"

default['jenkins']['server']['plugins'] = []
default['jenkins']['server']['jvm_options'] = nil
default['jenkins']['server']['pubkey'] = nil

default['jenkins']['http_proxy']['variant'] = 'nginx'
default['jenkins']['http_proxy']['www_redirect'] = 'disable'
default['jenkins']['http_proxy']['listen_ports'] = [80]
default['jenkins']['http_proxy']['host_name'] = nil
default['jenkins']['http_proxy']['host_aliases'] = []
default['jenkins']['http_proxy']['client_max_body_size'] = '1024m'
default['jenkins']['http_proxy']['basic_auth_username'] = 'jenkins'
default['jenkins']['http_proxy']['basic_auth_password'] = 'jenkins'
default['jenkins']['http_proxy']['cas_validate_server'] = 'off'
default['jenkins']['http_proxy']['server_auth_method'] = nil

default['jenkins']['http_proxy']['ssl']['enabled'] = false
default['jenkins']['http_proxy']['ssl']['redirect_http'] = false
default['jenkins']['http_proxy']['ssl']['ssl_listen_ports'] = [443]
default['jenkins']['http_proxy']['ssl']['dir'] = "#{default['jenkins']['server']['home']}/ssl"
default['jenkins']['http_proxy']['ssl']['cert_path'] = "#{default['jenkins']['http_proxy']['ssl']['dir']}/jenkins.cert"
default['jenkins']['http_proxy']['ssl']['key_path'] = "#{default['jenkins']['http_proxy']['ssl']['dir']}/jenkins.key"

# The username to log into jenkins dashboard (admin user)
default['jenkins']['username'] = nil

# The password to log into jenkins dashboard (admin user)
default['jenkins']['password'] = nil

# The full name of jenkins (admin) user
default['jenkins']['user_full_name'] = nil

# The email address of jenkins (admin) user
default['jenkins']['user_email'] = nil

# The permissions for the admin user. By default the user has all permissions.
default['jenkins']['user_permissions'] = [
  'Computer.Configure',
  'Computer.Connect',
  'Computer.Create',
  'Computer.Delete',
  'Computer.Disconnect',
  'Hudson.Administer',
  'Hudson.ConfigureUpdateCenter',
  'Hudson.Read',
  'Hudson.RunScripts',
  'Hudson.UploadPlugins',
  'Item.Build',
  'Item.Cancel',
  'Item.Configure',
  'Item.Create',
  'Item.Delete',
  'Item.Discover',
  'Item.Read',
  'Item.Workspace',
  'View.Configure',
  'View.Create',
  'View.Delete',
  'View.Read'
]
