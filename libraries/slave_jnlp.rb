#
# Cookbook Name:: jenkins
# HWRP:: jnlp_slave
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

class Chef
  class Resource::JenkinsJNLPSlave < Resource::JenkinsSlave
    # Chef attributes
    provides :jenkins_jnlp_slave

    # Set the resource name
    self.resource_name = :jenkins_jnlp_slave

    # Actions
    actions :create, :delete, :connect, :disconnect, :online, :offline
    default_action :create

    # Attributes
    attribute :group,
      kind_of: String,
      default: 'jenkins',
      regex: Config[:group_valid_regex]
    attribute :service_name,
      kind_of: String,
      default: 'jenkins-slave'
  end
end

class Chef
  class Provider::JenkinsJNLPSlave < Provider::JenkinsSlave
    def load_current_resource
      @current_resource ||= Resource::JenkinsJNLPSlave.new(new_resource.name)
      super
    end

    def action_create
      super

      parent_remote_fs_dir_resource.run_action(:create)

      # don't create user/group on Windows
      unless Chef::Platform.windows?
        group_resource.run_action(:create)
        user_resource.run_action(:create)
      end

      remote_fs_dir_resource.run_action(:create)
      slave_jar_resource.run_action(:create)

      service_resource.run_action(:enable) unless Chef::Platform.windows?
    end

    def action_delete
      # Stop and remove the service
      service_resource.run_action(:disable)

      super
    end

    protected

    #
    # @see Chef::Resource::JenkinsSlave#launcher_groovy
    # @see http://javadoc.jenkins-ci.org/hudson/slaves/JNLPLauncher.html
    #
    def launcher_groovy
      'launcher = new hudson.slaves.JNLPLauncher()'
    end

    #
    # The path (url) of the slave's unique JNLP file on the Jenkins
    # master.
    #
    # @return [String]
    #
    def jnlp_url
      @jnlp_url ||= uri_join(endpoint, 'computer', new_resource.slave_name, 'slave-agent.jnlp')
    end

    #
    # Generates the slaves unique JNLP secret using the Groovy API.
    #
    # @return [String]
    #
    def jnlp_secret
      return @jnlp_secret if @jnlp_secret
      json = executor.groovy! <<-EOH.gsub(/ ^{8}/, '')
        output = [
          secret:jenkins.slaves.JnlpSlaveAgentProtocol.SLAVE_SECRET.mac('#{new_resource.slave_name}')
        ]

        builder = new groovy.json.JsonBuilder(output)
        println(builder)
      EOH
      output = JSON.parse(json, symbolize_names: true)
      @jnlp_secret = output[:secret]
    end

    #
    # The url of the +slave.jar+ on the Jenkins master.
    #
    # @return [String]
    #
    def slave_jar_url
      @slave_jar_url ||= uri_join(endpoint, 'jnlpJars', 'slave.jar')
    end

    #
    # The path to the +slave.jar+ on disk (which may or may not exist).
    #
    # @return [String]
    #
    def slave_jar
      ::File.join(new_resource.remote_fs, 'slave.jar')
    end

    # Embedded Resources

    #
    # Creates a `group` resource that represents the system group
    # specified the `group` attribute. The caller will need to call
    # `run_action` on the resource.
    #
    # @return [Chef::Resource::Group]
    #
    def group_resource
      return @group_resource if @group_resource
      @group_resource = Chef::Resource::Group.new(new_resource.group, run_context)
      @group_resource
    end

    #
    # Creates a `user` resource that represents the system user
    # specified the `user` attribute. The caller will need to call
    # `run_action` on the resource.
    #
    # @return [Chef::Resource::User]
    #
    def user_resource
      return @user_resource if @user_resource
      @user_resource = Chef::Resource::User.new(new_resource.user, run_context)
      @user_resource.gid(new_resource.group)
      @user_resource.comment('Jenkins slave user - Created by Chef')
      @user_resource.home(new_resource.remote_fs)
      @user_resource
    end

    #
    # Creates the parent `directory` resource that is a level above where
    # the actual +remote_fs+ will live. This is required due to a Chef/RedHat
    # bug where +--create-home-dir+ behavior changed and broke the Internet.
    #
    # @return [Chef::Resource::Directory]
    #
    def parent_remote_fs_dir_resource
      return @parent_remote_fs_dir_resource if @parent_remote_fs_dir_resource

      path = ::File.expand_path(new_resource.remote_fs, '..')
      @parent_remote_fs_dir_resource = Chef::Resource::Directory.new(path, run_context)
      @parent_remote_fs_dir_resource.recursive(true)
      @parent_remote_fs_dir_resource
    end

    #
    # Creates a `directory` resource that represents the directory
    # specified the `remote_fs` attribute. The caller will need to call
    # `run_action` on the resource.
    #
    # @return [Chef::Resource::Directory]
    #
    def remote_fs_dir_resource
      return @remote_fs_dir_resource if @remote_fs_dir_resource
      @remote_fs_dir_resource = Chef::Resource::Directory.new(new_resource.remote_fs, run_context)
      @remote_fs_dir_resource.owner(new_resource.user)
      @remote_fs_dir_resource.group(new_resource.group)
      @remote_fs_dir_resource.recursive(true)
      @remote_fs_dir_resource
    end

    #
    # Creates a `remote_file` resource that represents the remote
    # +slave.jar+ file on the Jenkins master. The caller will need to
    # call `run_action` on the resource.
    #
    # @return [Chef::Resource::RemoteFile]
    #
    def slave_jar_resource
      return @slave_jar_resource if @slave_jar_resource
      @slave_jar_resource = Chef::Resource::RemoteFile.new(slave_jar, run_context)
      @slave_jar_resource.source(slave_jar_url)
      @slave_jar_resource.backup(false)
      @slave_jar_resource.mode('0755')
      @slave_jar_resource.atomic_update(false)
      @slave_jar_resource.notifies(:restart, service_resource)
      @slave_jar_resource
    end

    #
    # Returns a fully configured service resource that can start the
    # JNLP slave process. The caller will need to call `run_action` on
    # the resource.
    #
    # @return [Chef::Resource::RunitService]
    #
    def service_resource
      return @service_resource if @service_resource

      # Ensure runit is installed on the slave.
      recipe_eval do
        run_context.include_recipe 'runit'
      end

      @service_resource = Chef::Resource::RunitService.new(new_resource.service_name, run_context)
      @service_resource.cookbook('jenkins')
      @service_resource.run_template_name('jenkins-slave')
      @service_resource.log_template_name('jenkins-slave')
      @service_resource.options(
        new_resource: new_resource,
        java_bin:    java,
        slave_jar:   slave_jar,
        jnlp_url:    jnlp_url,
        jnlp_secret: jnlp_secret,
      )
      @service_resource
    end
  end
end

Chef::Platform.set(
  resource: :jenkins_jnlp_slave,
  provider: Chef::Provider::JenkinsJNLPSlave
)
