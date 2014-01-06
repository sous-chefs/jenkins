#
# Cookbook Name:: jenkins
# HWRP:: plugin
#
# Author:: Seth Vargo <sethvargo@gmail.com>
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

class Chef
  class Resource::JenkinsPlugin < Resource
    identity_attr :name

    attr_writer :installed

    def initialize(name, run_context = nil)
      super

      # Set the resource name and provider
      @resource_name = :jenkins_plugin
      @provider = Provider::JenkinsPlugin

      # Set default actions and allowed actions
      @action = :install
      @allowed_actions.push(:install, :uninstall, :enable, :disable)

      # Set the name attribute and default attributes
      @name    = name
      @version = :latest

      # State attributes that are set by the provider
      @installed = false
    end

    #
    # The name of the plugin to install. This _can_ be the shortname of the
    # plugin, but this can also be any random name of a plugin that does not
    # yet exist. If a source is not specified, however, this is assumed to be
    # the short name of the plugin in the update center.
    #
    # @param [String] arg
    # @return [String]
    #
    def name(arg = nil)
      set_or_return(:name, arg, kind_of: String)
    end

    #
    # The version of the plugin to install. The default version is +:latest+,
    # which pulls the latest plugin from the source or update center, however,
    # you can specify a specific version of the plugin to lock and install.
    #
    # @warn If the +source+ parameter is specified, this parameter is *ignored*,
    # since the source points to a specific +.jpi+ version.
    #
    # @param [String] arg
    # @return [String] arg
    #
    def version(arg = nil)
      set_or_return(:version, arg, kind_of: [String, Symbol])
    end

    #
    # The source where to pull this plugin from.
    #
    # @param [String] arg
    # @return [String]
    #
    def source(arg = nil)
      set_or_return(:source, arg, kind_of: String)
    end

    #
    # Determine if the plugin is installed on the server. This value is set by
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
  class Provider::JenkinsPlugin < Provider
    class PluginNotInstalled < StandardError
      def initialize(plugin, action)
        super "The Jenkins plugin `#{plugin}` is not installed. In order " \
              "to #{action} `#{plugin}`, that plugin must first be " \
              "installed on the Jenkins server!"
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
    end

    #
    # This provider supports why-run mode.
    #
    def whyrun_supported?
      true
    end

    def action_install
      # This block stores the actual command to execute, since its the same
      # for upgrades and installs.
      block = proc do
        # Use the remote_file resource to download and cache the plugin (see
        # comment below for more information).
        name   = "#{new_resource.name}-#{new_resource.version}.plugin"
        path   = ::File.join(Chef::Config[:file_cache_path], name)
        plugin = Chef::Resource::RemoteFile.new(path, run_context)
        plugin.source(plugin_source)
        plugin.backup(false)
        plugin.run_action(:create)

        # Install the plugin from our local cache on disk. There is a bug in
        # Jenkins that prevents Jenkins from following 302 redirects, so we
        # use Chef to download the plugin and then use Jenkins to install it.
        # It's a bit backwards, but so is Jenkins.
        executor.execute!('install-plugin', plugin.path, '-name', new_resource.name)
      end

      if current_resource.installed?
        if current_resource.version == new_resource.version ||
           new_resource.version.to_sym == :latest
          Chef::Log.debug("#{new_resource} already installed - skipping")
        else
          converge_by("Upgrade #{new_resource} from #{current_resource.version} to #{new_resource.version}", &block)
          notify(:restart)
        end
      else
        converge_by("Install #{new_resource}", &block)
        notify(:restart)
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
    def action_disable
      unless current_resource.installed?
        fail PluginNotInstalled.new(new_resource.name, :disable)
      end

      disabled = "#{plugin_file}.disabled"

      if ::File.exists?(disabled)
        Chef::Log.debug("#{new_resource} already disabled - skipping")
      else
        converge_by("Disable #{new_resource}") do
          Resource::File.new(disabled, run_context).run_action(:create)
        end
        notify(:restart)
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
    def action_enable
      unless current_resource.installed?
        fail PluginNotInstalled.new(new_resource.name, :enable)
      end

      disabled = "#{plugin_file}.disabled"

      if ::File.exists?(disabled)
        converge_by("Enable #{new_resource}") do
          Resource::File.new(disabled, run_context).run_action(:delete)
        end
        notify(:restart)
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
    # @warn Uninstalling a plugin, however, does not remove the configuration
    # that the plugin might have created. If there are existing
    # jobs/slaves/views/builds/etc that used some extensions from the plugin,
    # during the boot Jenkins will report that there are some fragments in
    # those configurations that it didn't understand, and pretend as if it
    # didn't see such a fragment.
    #
    def action_uninstall
      if current_resource.installed?
        converge_by("Uninstall #{new_resource}") do
          Resource::File.new(plugin_file, run_context).run_action(:delete)
          directory = Resource::Directory.new(plugin_data_directory, run_context)
          directory.recursive(true)
          directory.run_action(:delete)
        end
        notify(:restart)
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

      return nil unless ::File.exists?(manifest)

      @current_plugin = Hash[*::File.readlines(manifest).map do |line|
        next if line.strip.empty?

        config, value = line.split(' ', 2)
        config = config.gsub('-', '_').downcase.to_sym

        [config, value]
      end.compact.flatten]

      @current_plugin
    end

    #
    # The path to the plugins directory on the Jenkins node.
    #
    # @return [String]
    #
    def plugins_directory
      ::File.join(node['jenkins']['server']['home'], 'plugins')
    end

    #
    # The path to the actual plugin file on disk (+.jpi+)
    #
    def plugin_file
      hpi = ::File.join(plugins_directory, "#{new_resource.name}.hpi")
      jpi = ::File.join(plugins_directory, "#{new_resource.name}.jpi")

      ::File.exists?(hpi) ? hpi : jpi
    end

    #
    # The path to where the plugin stores its data on disk.
    #
    def plugin_data_directory
      ::File.join(plugins_directory, new_resource.name)
    end

    #
    # The source where to install the plugin from. This defaults to
    # +new_resource.source+. If that is not yet, a "default" URL is compiled
    # using the default Update Center.
    #
    # @return [String]
    #
    def plugin_source
      return new_resource.source if new_resource.source

      if new_resource.version.to_sym == :latest
        "https://updates.jenkins-ci.org/#{new_resource.version}/#{new_resource.name}.hpi"
      else
        "https://updates.jenkins-ci.org/download/plugins/#{new_resource.name}/#{new_resource.version}/#{new_resource.name}.hpi"
      end
    end

    #
    # Restart the Jenkins server. If the +restart+ parameter is given, the
    # server is restarted immediately. Otherwise, the server is restarted at
    # the end of the Chef Client run.
    #
    def notify(action)
      begin
        service = run_context.resource_collection.find('service[jenkins]')
      rescue Chef::Exceptions::ResourceNotFound
        Chef::Log.warn "I could not find service[jenkins] in the resource " \
                       "collection. The `jenkins_plugin` resource tries to " \
                       "#{action} the Jenkins Server automatically after a " \
                       "plugin is installed, but requires that a service " \
                       "resource exists for `jenkins`. If you are using " \
                       "your own Jenkins cookbook, you must manually " \
                       "create a Jenkins service resource."
        return
      end

      new_resource.notifies(action, service, :delayed)
    end
  end
end
