#
# Cookbook:: jenkins
# Resource:: plugin
#
# Author:: Seth Vargo <sethvargo@gmail.com>
# Author:: Seth Chisamore <schisamo@chef.io>
#
# Copyright:: 2013-2019, Chef Software, Inc.
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

require 'digest'

require_relative '_helper'

class Chef
  class Resource::JenkinsPlugin < Resource::LWRPBase
    resource_name :jenkins_plugin # Still needed for Chef 15 and below
    provides :jenkins_plugin

    # Chef attributes
    identity_attr :name

    # Actions
    actions :install, :uninstall, :enable, :disable
    default_action :install

    # Attributes
    attribute :version,
              kind_of: [String, Symbol],
              default: :latest
    attribute :source,
              kind_of: String
    # TODO: Remove in next major version release
    attribute :install_deps,
              kind_of: [TrueClass, FalseClass]
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
      !@installed.nil? && @installed
    end
  end
end

class Chef
  class Provider::JenkinsPlugin < Provider::LWRPBase
    provides :jenkins_plugin

    include Jenkins::Helper

    provides :jenkins_plugin

    class PluginNotInstalled < StandardError
      def initialize(plugin, action)
        super <<-EOH
The Jenkins plugin `#{plugin}' is not installed. In order to #{action}
`#{plugin}', that plugin must first be installed on the Jenkins master!
        EOH
      end
    end

    def load_current_resource
      @current_resource ||= Resource::JenkinsPlugin.new(new_resource.name)
      @current_resource.source(new_resource.source)
      @current_resource.version(new_resource.version)

      current_plugin = plugin_installation_manifest(new_resource.name)

      if current_plugin
        @current_resource.installed = true
        @current_resource.version(current_plugin['plugin_version'])
      else
        @current_resource.installed = false
      end

      @current_resource
    end

    action :install do
      # TODO: remove in next major version release
      # Check for dependency property and give deprecation if used
      if new_resource.install_deps
        Chef::Log.warn('The install_deps property on the plugin provider is deprecated and not used. See Readme on how to install plugins with or without dependencies.')
      end

      # This block stores the actual command to execute, since its the same
      # for upgrades and installs.
      install_block = proc do
        # Install a plugin from a given hpi (or jpi) if a link was provided.
        # In that case jenkins does not handle plugin dependencies automatically.
        # Otherwise the plugin is installed through the jenkins update-center
        # (default behaviour). In that case plugin dependencies are handled by jenkins.
        # if installing latest version
        install_plugin(
          new_resource.source,
          new_resource.name,
          new_resource.version,
          cli_opts: new_resource.options
        )
      end

      downgrade_block = proc do
        # remove the existing, newer version
        uninstall_plugin(new_resource.name)

        # proceed with a normal install
        install_block.call
      end

      if current_resource.installed?
        if plugin_version(current_resource.version) == desired_version
          Chef::Log.info("#{new_resource} version #{current_resource.version} already installed - skipping")
        else
          current_version = plugin_version(current_resource.version)
          unless current_version.to_s.include? 'SNAPSHOT'
            if plugin_upgrade?(current_version, desired_version)
              converge_by("Upgrade #{new_resource} from #{current_resource.version} to #{desired_version}", &install_block)
            else
              converge_by("Downgrade #{new_resource} from #{current_resource.version} to #{desired_version}", &downgrade_block)
            end
          end
        end
      else
        converge_by("Install #{new_resource}", &install_block)
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
    action :disable do
      raise PluginNotInstalled.new(new_resource.name, :disable) unless current_resource.installed?

      disabled = "#{plugin_file(new_resource.name)}.disabled"

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
    action :enable do
      raise PluginNotInstalled.new(new_resource.name, :enable) unless current_resource.installed?

      disabled = "#{plugin_file(new_resource.name)}.disabled"

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
    action :uninstall do
      if current_resource.installed?
        converge_by("Uninstall #{new_resource}") do
          uninstall_plugin(new_resource.name)
        end
      else
        Chef::Log.debug("#{new_resource} not installed - skipping")
      end
    end

    private

    def desired_version(name = nil, version = nil)
      name = new_resource.name if name.nil?
      version = new_resource.version if version.nil?

      if version.to_sym == :latest
        remote_plugin_data = plugin_universe[name]

        return :latest unless remote_plugin_data

        plugin_version(remote_plugin_data['version'])
      else
        plugin_version(version)
      end
    end

    #
    # Installs a plugin along with all of it's dependencies if version is :latest and source property is not specified.
    #
    # @param [String] full url of the *.hpi/*.jpi to install
    # @param [String] name of the plugin to be installed
    # @param [String] version of the plugin to be installed
    # @param [Hash] opts the options install plugin with
    # @option opts [Boolean] :cli_opts additional flags to pass the jenkins cli command
    #
    def install_plugin(source_url, plugin_name, plugin_version, opts = {})
      test = (source_url || plugin_version != :latest) ? true : false
      if test
        url = if source_url
                source_url
              else
                remote_plugin_data = plugin_universe[plugin_name]
                # Compute some versions; Parse them as `Gem::Version` instances for easy comparisons.
                latest_version = plugin_version(remote_plugin_data['version'])
                # Replace the latest version with the desired version in the URL
                remote_plugin_data['url'].gsub!(latest_version.to_s, desired_version(plugin_name, plugin_version).to_s)
              end
      end
      ensure_update_center_present!
      executor.execute!('install-plugin', escape(test ? url : plugin_name), opts[:cli_opts])
    end

    #
    # Uninstalling a plugin removes the plugin binary (*.jpi) from the disk.
    #
    # @param [String] name of the plugin to be uninstall
    #
    def uninstall_plugin(plugin_name)
      file = Resource::File.new(plugin_file(plugin_name), run_context)
      file.backup(false)
      file.run_action(:delete)
      directory = Resource::Directory.new(plugin_data_directory(plugin_name), run_context)
      directory.recursive(true)
      directory.run_action(:delete)
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
    # @param [String] name of the plugin to be installed
    # @return [String]
    #
    def plugin_file(plugin_name)
      hpi = ::File.join(plugins_directory, "#{plugin_name}.hpi")
      jpi = ::File.join(plugins_directory, "#{plugin_name}.jpi")

      ::File.exist?(hpi) ? hpi : jpi
    end

    #
    # The path to where the plugin stores its data on disk.
    #
    def plugin_data_directory(plugin_name)
      ::File.join(plugins_directory, plugin_name)
    end

    #
    # Parsed hash of all known Jenkins plugins
    #
    # @return [Hash]
    #
    def plugin_universe
      @plugin_universe ||= begin
        ensure_update_center_present!
        JSON.parse(IO.read(extracted_update_center_json).force_encoding('UTF-8'))['plugins']
      end
    end

    #
    # Return the installation manifest for +plugin_name+. If the plugin is not
    # installed +nil+ is returned.
    #
    # @param [String] name of the plugin to be installed
    # @return [Hash]
    #
    def plugin_installation_manifest(plugin_name)
      manifest = ::File.join(plugins_directory, plugin_name, 'META-INF', 'MANIFEST.MF')
      Chef::Log.debug "Load #{plugin_name} plugin information from #{manifest}"

      return unless ::File.exist?(manifest)

      plugin_manifest = {}

      ::File.open(manifest, 'r', encoding: 'utf-8') do |file|
        file.each_line do |line|
          next if line.strip.empty?

          #
          # Example Data:
          #   Plugin-Version: 1.4
          #
          config, value = line.split(/:\s/, 2)
          config = config.tr('-', '_').downcase
          value = value.strip if value # remove trailing \r\n

          plugin_manifest[config] = value
        end
      end

      plugin_manifest
    end

    #
    # Return whether plugin should be upgraded to desired version
    # (i.e. that current < desired).
    # https://github.com/chef-cookbooks/jenkins/issues/380
    # If only one of the two versions is a Gem::Version, we
    # fallback to String comparison.
    #
    # @param [Gem::Version, String] current_version
    # @param [Gem::Version, String] desired_version
    # @return [Boolean]
    #
    def plugin_upgrade?(current_version, desired_version)
      current_version < desired_version
    rescue ArgumentError
      current_version.to_s < desired_version.to_s
    end

    #
    # Return the plugin version for +version+.
    # https://github.com/chef-cookbooks/jenkins/issues/292
    # Prefer to use Gem::Version as that will be more accurate than
    # comparing strings, but sadly Jenkins plugins may not always
    # follow "normal" version patterns
    #
    # @param [String] version
    # @return [String]
    #
    def plugin_version(version)
      gem_version = Gem::Version.new(version)
      gem_version.prerelease? ? version : gem_version
    rescue ArgumentError
      version
    end
  end
end
