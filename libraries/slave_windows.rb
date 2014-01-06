#
# Cookbook Name:: jenkins
# HWRP:: windows_slave
#
# Author:: Seth Chisamore <schisamo@getchef.com>
#
# Copyright 2013, Chef Software, Inc.
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

require 'uri'
require_relative 'slave_jnlp'

class Chef
  class Resource::JenkinsWindowsSlave < Resource::JenkinsJNLPSlave
    provides :jenkins_jnlp_slave, on_platforms: ['windows']

    def initialize(name, run_context = nil)
      super

      # Set the provider
      @provider = Provider::JenkinsWindowsSlave

      # Set the default attributes
      @remote_fs = 'C:\jenkins'
      @user      = 'LocalSystem'
      @password  = nil
      @winsw_url = 'http://repo.jenkins-ci.org/releases/com/sun/winsw/winsw/1.13/winsw-1.13-bin.exe'
    end

    #
    # Password of the user that manages the slave process. This is used
    # to configure the service that manages the slave process.
    #
    # @param [String] arg
    # @return [String]
    #
    def password(arg = nil)
      set_or_return(:password, arg, kind_of: String)
    end

    #
    # URL of the `winsw` wrapper executable which is used to install the
    # Windows service which launches the slave process.
    #
    # @see https://github.com/kohsuke/winsw
    # @param [String] arg
    # @return [String]
    #
    def winsw_url(arg = nil)
      set_or_return(:winsw_url, arg, kind_of: String)
    end
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
      slave_exe = ::File.join(new_resource.remote_fs, 'jenkins-slave.exe')
      @slave_exe_resource = Chef::Resource::RemoteFile.new(slave_exe, run_context)
      @slave_exe_resource.source(new_resource.winsw_url)
      @slave_exe_resource.backup(false)
      @slave_exe_resource.notifies(:restart, "service[#{new_resource.service_name}]")
      @slave_exe_resource
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

      slave_xml = ::File.join(new_resource.remote_fs, 'jenkins-slave.xml')
      # Determine if our user has a domain
      user_parts = new_resource.user.match(/(.*)\\(.*)/)
      if user_parts
        user_domain = match[1]
        user_account   = match[2]
      else
        user_domain = nil
        user_account   = new_resource.user
      end

      @slave_xml_resource = Chef::Resource::Template.new(slave_xml, run_context)
      @slave_xml_resource.cookbook('jenkins')
      @slave_xml_resource.source('jenkins-slave.xml.erb')
      @slave_xml_resource.variables(
        new_resource: new_resource,
        java_bin: java,
        slave_jar: slave_jar,
        jnlp_url: jnlp_url,
        jnlp_secret: jnlp_secret,
        user_domain: user_domain,
        user_account: user_account,
        user_password: new_resource.password
      )
      @slave_xml_resource.notifies(:restart, "service[#{new_resource.service_name}]")
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
      @install_service_resource.command('jenkins-slave.exe install')
      @install_service_resource.cwd(new_resource.remote_fs)
      @install_service_resource.only_if do
        WMI::Win32_Service.find(
          :first,
          :conditions => { :name => new_resource.service_name }
        ).nil?
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
        !WMI::Win32_Service.find(
          :first,
          :conditions => { :name => new_resource.service_name }
        ).nil?
      end
      @service_resource
    end
  end
end
