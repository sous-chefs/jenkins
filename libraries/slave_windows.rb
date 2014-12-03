#
# Cookbook Name:: jenkins
# HWRP:: windows_slave
#
# Author:: Seth Chisamore <schisamo@getchef.com>
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

require_relative '_params_validate'
require_relative 'slave'
require_relative 'slave_jnlp'

class Chef
  class Resource::JenkinsWindowsSlave < Resource::JenkinsJNLPSlave
    # Chef attributes
    provides :jenkins_windows_slave, on_platforms: %w(windows)

    # Set the resource name
    self.resource_name = :jenkins_windows_slave

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
      default: 'http://repo.jenkins-ci.org/releases/com/sun/winsw/winsw/1.16/winsw-1.16-bin.exe'
    attribute :winsw_checksum,
      kind_of: String,
      default: '052f82c167fbe68a4025bcebc19fff5f11b43576a2ec62b0415432832fa2272d'
    attribute :path,
      kind_of: String
  end
end

class Chef
  class Provider::JenkinsWindowsSlave < Provider::JenkinsJNLPSlave
    def load_current_resource
      @current_resource ||= Resource::JenkinsWindowsSlave.new(new_resource.name)
      super
    end

    #
    # @see Chef::Resource::JenkinsSlave#action_create
    #
    def action_create
      super

      # The following resources are created in the parent:
      #
      #  * remote_fs_dir_resource
      #  * slave_jar_resource
      #
      slave_exe_resource.run_action(:create)
      slave_compat_xml.run_action(:create)
      slave_xml_resource.run_action(:create)
      install_service_resource.run_action(:run)
      service_resource.run_action(:start)
    end

    protected

    # Embedded Resources

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
      @slave_compat_xml.content(<<-EOH.gsub(/ ^{8}/, '')
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
      # Determine if our user has a domain
      user_parts = new_resource.user.match(/(.*)\\(.*)/)
      if user_parts
        user_domain = match[1]
        user_account   = match[2]
      else
        user_domain = "."
        user_account   = new_resource.user
      end

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
        path:          new_resource.path,
      )
      @slave_xml_resource.notifies(:restart, service_resource)
      @slave_xml_resource
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

      description = "Install '#{new_resource.service_name}' service"
      @install_service_resource = Chef::Resource::Execute.new(description, run_context)
      @install_service_resource.command("#{new_resource.service_name}.exe install")
      @install_service_resource.cwd(new_resource.remote_fs)
      @install_service_resource.not_if do
        wmi_property_from_query(:name, "select * from Win32_Service where name = '#{new_resource.service_name}'")
      end
      @install_service_resource
    end

    #
    # @see Chef::Resource::JenkinsJNLPSlave#service_resource
    #
    def service_resource
      return @service_resource if @service_resource

      @service_resource = Chef::Resource::Service.new(new_resource.service_name, run_context)
      @service_resource.only_if do
        wmi_property_from_query(:name, "select * from Win32_Service where name = '#{new_resource.service_name}'")
      end
      @service_resource
    end
  end
end

Chef::Platform.set(
  resource: :jenkins_windows_slave,
  platform: :windows,
  provider: Chef::Provider::JenkinsWindowsSlave
)
