#
# Cookbook:: jenkins
# HWRP:: windows_slave
#
# Author:: Seth Chisamore <schisamo@chef.io>
#
# Copyright:: 2013-2017, Chef Software, Inc.
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

require_relative 'slave'
require_relative 'slave_jnlp'

class Chef
  class Resource::JenkinsWindowsSlave < Resource::JenkinsJnlpSlave
    resource_name :jenkins_windows_slave

    # Actions
    actions :create, :delete, :connect, :disconnect, :online, :offline
    default_action :create

    # Attributes
    attribute :password,
              kind_of: String
    attribute :user,
              kind_of: String,
              default: 'LocalSystem'
    attribute :remote_fs,
              kind_of: String,
              default: 'C:\jenkins'
    attribute :winsw_url,
              kind_of: String,
              default: 'http://repo.jenkins-ci.org/releases/com/sun/winsw/winsw/1.17/winsw-1.17-bin.exe'
    attribute :winsw_checksum,
              kind_of: String,
              default: '5859b114d96800a2b98ef9d19eaa573a786a422dad324547ef25be181389df01'
    attribute :path,
              kind_of: String
    attribute :pre_run_cmds,
              kind_of: Array,
              default: []
  end
end

class Chef
  class Provider::JenkinsWindowsSlave < Provider::JenkinsJnlpSlave
    use_inline_resources
    provides :jenkins_windows_slave, platform: %w(windows)

    def load_current_resource
      @current_resource ||= Resource::JenkinsWindowsSlave.new(new_resource.name)
      super
    end

    #
    # @see Chef::Resource::JenkinsSlave#action_create
    #
    action :create do
      do_create

      # The following resources are created in the parent:
      #
      #  * remote_fs_dir_resource
      #  * slave_jar_resource
      #

      # The jenkins-slave.exe is needed to get the slave up and running under a windows service.
      # However, once it is created Jenkins Master wants to control the version.  So we should only
      # create the file if it is missing.
      slave_exe_resource.run_action(:create_if_missing)
      slave_jar_resource.run_action(:create)
      slave_compat_xml.run_action(:create)
      slave_bat_resource.run_action(:create)
      slave_xml_resource.run_action(:create)
      install_service_resource.run_action(:run) if slave_xml_resource.updated?

      # We need to restart the service if the slave jar or bat file change
      if slave_jar_resource.updated? || slave_bat_resource.updated?
        service_resource.run_action(:restart)
      # otherwise just ensure it's running
      else
        service_resource.run_action(:start)
      end
    end

    private

    # Embedded Resources

    # Creates a `directory` resource that represents the directory
    # specified the `remote_fs` attribute. The caller will need to call
    # `run_action` on the resource.
    #
    # @return [Chef::Resource::Directory]
    #
    def remote_fs_dir_resource
      return @remote_fs_dir_resource if @remote_fs_dir_resource
      @remote_fs_dir_resource = Chef::Resource::Directory.new(new_resource.remote_fs, run_context)
      @remote_fs_dir_resource.rights(:full_control, new_resource.user)
      @remote_fs_dir_resource.recursive(true)
      @remote_fs_dir_resource
    end

    #
    # Creates a `remote_file` resource that represents the remote
    # +winsw.exe+ file. This file is a wrapper executable that is used
    # to create a Window's service. The caller will need to call
    # `run_action` on the resource.
    #
    # @return [Chef::Resource::RemoteFile]
    #
    def slave_exe_resource
      return @slave_exe_resource if @slave_exe_resource
      slave_exe = ::File.join(new_resource.remote_fs, "#{new_resource.service_name}.exe")
      @slave_exe_resource = Chef::Resource::RemoteFile.new(slave_exe, run_context)
      @slave_exe_resource.source(new_resource.winsw_url)
      @slave_exe_resource.checksum(new_resource.winsw_checksum)
      @slave_exe_resource.backup(false)
      @slave_exe_resource
    end

    #
    # winsw technically only runs under .NET 2.0 but we can force 4.0
    # compat by dropping off the following file. More details at:
    #
    #   https://github.com/kohsuke/winsw#net-runtime-40
    #
    # The caller will need to call `run_action` on the resource.
    #
    # @return [Chef::Resource::File]
    #
    def slave_compat_xml
      return @slave_compat_xml if @slave_compat_xml
      slave_compat_xml = ::File.join(new_resource.remote_fs, "#{new_resource.service_name}.exe.config")
      @slave_compat_xml = Chef::Resource::File.new(slave_compat_xml, run_context)
      @slave_compat_xml.content(
        <<-EOH.gsub(/ ^{8}/, '')
        <configuration>
          <startup>
            <supportedRuntime version="v2.0.50727" />
            <supportedRuntime version="v4.0" />
          </startup>
        </configuration>
        EOH
      )
      @slave_compat_xml
    end

    #
    # Creates a `template` resource that represents the config file used
    # to create the Window's service. The caller will need to call
    # `run_action` on the resource.
    #
    # @return [Chef::Resource::Template]
    #
    def slave_xml_resource
      return @slave_xml_resource if @slave_xml_resource

      slave_xml = ::File.join(new_resource.remote_fs, "#{new_resource.service_name}.xml")

      @slave_xml_resource = Chef::Resource::Template.new(slave_xml, run_context)
      @slave_xml_resource.cookbook('jenkins')
      @slave_xml_resource.source('jenkins-slave.xml.erb')
      @slave_xml_resource.variables(
        new_resource:  new_resource,
        endpoint:      endpoint,
        java_bin:      java,
        slave_jar:     slave_jar,
        jnlp_url:      jnlp_url,
        jnlp_secret:   jnlp_secret,
        user_domain:   user_domain,
        user_account:  user_account,
        user_password: new_resource.password,
        path:          new_resource.path
      )
      @slave_xml_resource.notifies(:run, install_service_resource)
      @slave_xml_resource
    end

    #
    # Create bat file from jenkins-slave.bat.erb to launches Jenkins jar as
    # service. Optionally run any commands in :pre_run_cmds before launching jar
    #
    # @return [Chef::Resource::Template]
    #
    def slave_bat_resource
      return @slave_bat_resource if @slave_bat_resource

      slave_bat = ::File.join(new_resource.remote_fs, 'jenkins-slave.bat')

      @slave_bat_resource = Chef::Resource::Template.new(slave_bat, run_context)
      @slave_bat_resource.cookbook('jenkins')
      @slave_bat_resource.source('jenkins-slave.bat.erb')
      @slave_bat_resource.variables(
        pre_run_cmds:  new_resource.pre_run_cmds,
        new_resource:  new_resource,
        java_bin:      java,
        slave_jar:     slave_jar,
        jnlp_url:      jnlp_url,
        jnlp_secret:   jnlp_secret
      )
      @slave_bat_resource
    end

    #
    # Creates an `execute` resource which is used to install the
    # Window's service. The caller will need to call `run_action` on the
    # resource.
    #
    # @return [Chef::Resource::Template]
    #
    def install_service_resource
      return @install_service_resource if @install_service_resource

      code = <<-EOH.gsub(/ ^{8}/, '')
        IF "#{wmi_property_from_query(:name, "select * from Win32_Service where name = '#{new_resource.service_name}'")}" == "#{new_resource.service_name}" (
          #{new_resource.service_name}.exe stop
          #{new_resource.service_name}.exe uninstall
        )
        #{new_resource.service_name}.exe install
      EOH

      @install_service_resource = Chef::Resource::Batch.new("install-#{new_resource.service_name}", run_context)
      @install_service_resource.code(code)
      @install_service_resource.cwd(new_resource.remote_fs)
      @install_service_resource
    end

    #
    # @see Chef::Resource::JenkinsJNLPSlave#service_resource
    #
    def service_resource
      return @service_resource if @service_resource

      @service_resource = Chef::Resource.resource_for_node(:service, node).new(new_resource.service_name, run_context)
      @service_resource.only_if do
        wmi_property_from_query(:name, "select * from Win32_Service where name = '#{new_resource.service_name}'")
      end
      @service_resource
    end

    #
    # Windows domain for the user or `.` if a domain is not set.
    #
    # @return [String]
    #
    def user_domain
      @user_domain ||= begin
        if (parts = new_resource.user.match(/(?<domain>.*)\\(?<account>.*)/))
          parts[:domain]
        else
          '.'
        end
      end
    end

    #
    # Account name of the configured user. The domain prefix is also properly
    # stripped off.
    #
    # @return [String]
    #
    def user_account
      @user_account ||= begin
        if (parts = new_resource.user.match(/(?<domain>.*)\\(?<account>.*)/))
          parts[:account]
        else
          new_resource.user
        end
      end
    end
  end
end
