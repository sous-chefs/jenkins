#
# Cookbook Name:: jenkins
# Provider:: plugin
#
# Copyright 2013, Opscode, Inc.
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

def whyrun_supported?
  true
end

def load_current_resource
  @current_resource = Chef::Resource::JenkinsPlugin.new(@new_resource.name)
  @current_resource
end

action :install do
  if plugin_exists?
    Chef::Log.debug "#{@new_resource} already exists"
  else
    converge_by("install #{@new_resource}") do
      do_install_plugin
    end
  end
end

action :remove do
  if plugin_exists?
    converge_by("remove #{@new_resource}") do
      do_remove_plugin
    end
  else
    Chef::Log.debug "#{@new_resource} doesn't exist"
  end
end


private

def plugin_exists?
  ::File.exists?(plugin_file_path)
end

def plugin_dir_path
  ::File.join(plugins_dir, @new_resource.name)
end

def plugin_file_path
  ::File.join(plugins_dir, "#{@new_resource.name}.jpi")
end

def plugins_dir
  ::File.join(node['jenkins']['server']['home'], 'plugins')
end


def do_install_plugin
  name = @new_resource.name
  version = @new_resource.version || 'latest'

  # Plugins installed from the Jenkins Update Center are written to disk with
  # the `*.jpi` extension. Although plugins downloaded from the Jenkins Mirror
  # have an `*.hpi` extension we will save the plugins with a `*.jpi` extension
  # to match Update Center's behavior.
  remote_file plugin_file_path do
    source "#{node['jenkins']['mirror']}/plugins/#{name}/#{version}/#{name}.hpi"
    owner node['jenkins']['server']['user']
    group node['jenkins']['server']['group']
    backup false
    action :create
    notifies :restart, "service[jenkins]"
    notifies :create, "ruby_block[block_until_operational]"
  end
end

def do_remove_plugin
  file plugin_file_path do
    action :delete
    backup false
    notifies :restart, "service[jenkins]"
    notifies :create, "ruby_block[block_until_operational]"
  end

  directory plugin_dir_path do
    action :delete
    recursive true
    notifies :restart, "service[jenkins]"
    notifies :create, "ruby_block[block_until_operational]"
  end
end
