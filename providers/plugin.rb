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
  @current_resource.version(current_version)
  @current_resource
end

action :install do
  @new_resource.version('latest') unless @new_resource.version

  Chef::Log.debug "#{@new_resource}: current version=#{@current_resource.version}, requested version=#{@new_resource.version}"

  # TODO: If @new_resource.version == 'latest', lookup the new version
  # and assign it to @new_resource.version

  if @current_resource.version && @new_resource.version != 'latest' && @current_resource.version != @new_resource.version
    converge_by("Upgrading #{@new_resource} from #{@current_resource.version} to #{@new_resource.version}") do
      do_upgrade_plugin
    end
  elsif plugin_exists?
    Chef::Log.debug "#{@new_resource} already exists"
  else
    converge_by("Installing #{@new_resource} version #{@new_resource.version}") do
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
  def current_version
    current_version = nil
    manifest_file = ::File.join(plugins_dir, @current_resource.name, 'META-INF', 'MANIFEST.MF')
    if ::File.exist?(manifest_file)
      manifest = IO.read(manifest_file)
      current_version = manifest.match(/^Plugin-Version:\s*(.+)$/)[1].strip
    end
    current_version
  end

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
    plugin_url = @new_resource.url

    # Plugins installed from the Jenkins Update Center are written to disk with
    # the `*.jpi` extension. Although plugins downloaded from the Jenkins Mirror
    # have an `*.hpi` extension we will save the plugins with a `*.jpi` extension
    # to match Update Center's behavior.
    remote_file plugin_file_path do
      source plugin_url
      owner node['jenkins']['server']['user']
      group node['jenkins']['server']['plugins_dir_group']
      backup false
      action :create
      notifies :restart, 'service[jenkins]'
      notifies :create, 'ruby_block[block_until_operational]'
    end

    file "#{plugin_file_path}.pinned" do
      action :create_if_missing
      owner node['jenkins']['server']['user']
      group node['jenkins']['server']['group']
    end
  end

  def do_upgrade_plugin
    do_install_plugin
  end

  def do_remove_plugin
    file plugin_file_path do
      action :delete
      backup false
      notifies :restart, 'service[jenkins]'
      notifies :create, 'ruby_block[block_until_operational]'
    end

    directory plugin_dir_path do
      action :delete
      recursive true
      notifies :restart, 'service[jenkins]'
      notifies :create, 'ruby_block[block_until_operational]'
    end
  end
