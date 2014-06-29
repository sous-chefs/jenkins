#
# Cookbook Name:: jenkins
# HWRP:: plugin
#
# Author:: Seth Vargo <sethvargo@gmail.com>
#
# Copyright 2013-2014, Chef Software, Inc.
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

require_relative '_helper'
require_relative '_params_validate'

class Chef
  class Resource::JenkinsPlugin < Resource::LWRPBase
    # Chef attributes
    identity_attr :name
    provides :jenkins_plugin

    # Set the resource name
    self.resource_name = :jenkins_plugin

    # Actions
    actions :install, :uninstall, :enable, :disable
    default_action :install

    # Attributes
    attribute :name,
      kind_of: String,
      name_attribute: true
    attribute :version,
      kind_of: [String, Symbol],
      default: :latest
    attribute :source,
      kind_of: String
    attribute :options,
      kind_of: String

    attr_writer :installed

    #
    # Determine if the plugin is installed on the master. This value is set by
    # the provider when the current resource is loaded.
    #
    # @return [Boolean]
    #
    def installed?
      !!@installed
    end
  end
end

class Chef
  class Provider::JenkinsPlugin < Provider::LWRPBase
    class PluginNotInstalled < StandardError
      def initialize(plugin, action)
        super <<-EOH
The Jenkins plugin `#{plugin}' is not installed. In order to #{action}
`#{plugin}', that plugin must first be installed on the Jenkins master!
EOH
      end
    end

    include Jenkins::Helper

    def load_current_resource
      @current_resource ||= Resource::JenkinsPlugin.new(new_resource.name)
      @current_resource.source(new_resource.source)
      @current_resource.version(new_resource.version)

      if current_plugin
        @current_resource.installed = true
        @current_resource.version(current_plugin[:plugin_version])
      else
        @current_resource.installed = false
      end

      @current_resource
    end

    #
    # This provider supports why-run mode.
    #
    def whyrun_supported?
      true
    end

    action(:install) do
      # This block stores the actual command to execute, since its the same
      # for upgrades and installs.
      block = proc do
        # Install a plugin from a given hpi (or jpi) if a link was provided.
        # In that case jenkins does not handle plugin dependencies automatically.
        # Otherwise the plugin is installed through the jenkins update-center
        # (default behaviour). In that case plugin dependencies are handled by jenkins.
        if new_resource.source
          # Use the remote_file resource to download and cache the plugin (see
          # comment below for more information).
          name   = "#{new_resource.name}-#{new_resource.version}.plugin"
          path   = ::File.join(Chef::Config[:file_cache_path], name)
          plugin = Chef::Resource::RemoteFile.new(path, run_context)
          plugin.source(new_resource.source)
          plugin.backup(false)
          plugin.run_action(:create)

          # Install the plugin from our local cache on disk. There is a bug in
          # Jenkins that prevents Jenkins from following 302 redirects, so we
          # use Chef to download the plugin and then use Jenkins to install it.
          # It's a bit backwards, but so is Jenkins.
          executor.execute!('install-plugin', escape(plugin.path), '-name', escape(new_resource.name), new_resource.options)
        else
          # Install the plugin from the update-center. This results in the
          # same behaviour as using the UI to install plugins.
          executor.execute!('install-plugin', escape(new_resource.name), new_resource.options)
        end
      end

      if current_resource.installed?
        if current_resource.version == new_resource.version ||
           new_resource.version.to_sym == :latest
          Chef::Log.debug("#{new_resource} already installed - skipping")
        else
          converge_by("Upgrade #{new_resource} from #{current_resource.version} to #{new_resource.version}", &block)
        end
      else
        converge_by("Install #{new_resource}", &block)
      end
    end

    #
    # Disable the given plugin.
    #
    # Disabling a plugin is a softer way to retire a plugin. Jenkins will
    # continue to recognize that the plugin is installed, but it will not
    # start the plugin, and no extensions contributed from this plugin will be
    # visible.
    #
    # The fragments contributed from a disabled plugin to configuration files
    # would follow the same fate as in the case of uninstalled plugins.
    #
    # Plugins that are disabled can be re-enabled from the UI (or by removing
    # *.jpi.disabled file from the disk.)
    #
    action(:disable) do
      unless current_resource.installed?
        fail PluginNotInstalled.new(new_resource.name, :disable)
      end

      disabled = "#{plugin_file}.disabled"

      if ::File.exist?(disabled)
        Chef::Log.debug("#{new_resource} already disabled - skipping")
      else
        converge_by("Disable #{new_resource}") do
          Resource::File.new(disabled, run_context).run_action(:create)
        end
      end
    end

    #
    # Enable the given plugin.
    #
    # Enabling a plugin brings back a formerly disabled plugin. Jenkins will
    # being recognizing this plugin again on the next restart.
    #
    # Plugins may be disabled by re-adding the +.jpi.disabled+ plugin.
    #
    action(:enable) do
      unless current_resource.installed?
        fail PluginNotInstalled.new(new_resource.name, :enable)
      end

      disabled = "#{plugin_file}.disabled"

      if ::File.exist?(disabled)
        converge_by("Enable #{new_resource}") do
          Resource::File.new(disabled, run_context).run_action(:delete)
        end
      else
        Chef::Log.debug("#{new_resource} already enabled - skipping")
      end
    end

    #
    # Uninstall the given plugin.
    #
    # Uninstalling a plugin removes the plugin binary (*.jpi) from the disk.
    # The plugin continues to function normally until you restart Jenkins, but
    # once you restart, Jenkins will behave as if you didn't have the plugin
    # to being with. They will not appear anywhere in the UI, all the
    # extensions they contributed will disappear.
    #
    # WARNING: Uninstalling a plugin, however, does not remove the configuration
    # that the plugin might have created. If there are existing
    # jobs/slaves/views/builds/etc that used some extensions from the plugin,
    # during the boot Jenkins will report that there are some fragments in
    # those configurations that it didn't understand, and pretend as if it
    # didn't see such a fragment.
    #
    action(:uninstall) do
      if current_resource.installed?
        converge_by("Uninstall #{new_resource}") do
          Resource::File.new(plugin_file, run_context).run_action(:delete)
          directory = Resource::Directory.new(plugin_data_directory, run_context)
          directory.recursive(true)
          directory.run_action(:delete)
        end
      else
        Chef::Log.debug("#{new_resource} not installed - skipping")
      end
    end

    private

    #
    # Loads the local plugin into a hash
    #
    def current_plugin
      return @current_plugin if @current_plugin

      manifest = ::File.join(plugins_directory, new_resource.name, 'META-INF', 'MANIFEST.MF')
      Chef::Log.debug "Load #{new_resource} plugin information from #{manifest}"

      return nil unless ::File.exist?(manifest)

      @current_plugin = {}

      ::File.open(manifest, 'r', encoding: 'utf-8') do |file|
        file.each_line do |line|
          next if line.strip.empty?

          #
          # Example Data:
          #   Plugin-Version: 1.4
          #
          config, value = line.split(/:\s/, 2)
          config = config.gsub('-', '_').downcase.to_sym
          value = value.strip if value # remove trailing \r\n

          @current_plugin[config] = value
        end
      end
    end

    #
    # The path to the plugins directory on the Jenkins node.
    #
    # @return [String]
    #
    def plugins_directory
      ::File.join(node['jenkins']['master']['home'], 'plugins')
    end

    #
    # The path to the actual plugin file on disk (+.jpi+)
    #
    def plugin_file
      hpi = ::File.join(plugins_directory, "#{new_resource.name}.hpi")
      jpi = ::File.join(plugins_directory, "#{new_resource.name}.jpi")

      ::File.exist?(hpi) ? hpi : jpi
    end

    #
    # The path to where the plugin stores its data on disk.
    #
    def plugin_data_directory
      ::File.join(plugins_directory, new_resource.name)
    end
  end
end

Chef::Platform.set(
  resource: :jenkins_plugin,
  provider: Chef::Provider::JenkinsPlugin
)
