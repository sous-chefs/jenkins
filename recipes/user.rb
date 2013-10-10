#
# Author:: Kannan Manickam <kannan@rightscale.com>
#
# Cookbook Name:: jenkins
# Recipe:: user
#
# Copyright 2013, RightScale, Inc.
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

template "#{node['jenkins']['server']['home']}/config.xml" do
  source 'jenkins-config.xml.erb'
  owner node['jenkins']['server']['user']
  group node['jenkins']['server']['group']
  mode '0644'
  variables(
    :username => node['jenkins']['server']['username'],
    :user_permissions => node['jenkins']['server']['user_permissions']
  )
  notifies :restart, 'service[jenkins]'
end

directory "#{node['jenkins']['server']['home']}/users/#{node['jenkins']['server']['username']}" do
  owner node['jenkins']['server']['user']
  group node['jenkins']['server']['group']
  recursive true
end

# Obtain the hash of the password.
chef_gem 'bcrypt-ruby'
require 'bcrypt'

# Generate the password hash
password_hash = ::BCrypt::Password.create(node['jenkins']['server']['password'])

template "#{node['jenkins']['server']['home']}/users/#{node['jenkins']['server']['username']}/config.xml" do
  source 'jenkins-user-config.xml.erb'
  owner node['jenkins']['server']['user']
  group node['jenkins']['server']['group']
  mode '0644'
  variables(
    :user_full_name => node['jenkins']['server']['user_full_name'],
    :user_email => node['jenkins']['server']['user_email'],
    :password_hash => password_hash
  )
  notifies :restart, 'service[jenkins]'
end
