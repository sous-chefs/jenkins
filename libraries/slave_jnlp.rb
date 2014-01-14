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

require 'uri'
require_relative 'slave'

class Chef
  class Resource::JenkinsJNLPSlave < Resource::JenkinsSlave
    provides :jenkins_jnlp_slave

    def initialize(name, run_context = nil)
      super

      # Set the resource name and provider
      @resource_name = :jenkins_jnlp_slave
      @provider = Provider::JenkinsJNLPSlave

      # Set the default attributes
      @service_name    = 'jenkins-slave'
    end

    #
    # Name of the service that manages the slave process.
    #
    # @param [String] arg
    # @return [String]
    #
    def service_name(arg = nil)
      set_or_return(:service_name, arg, kind_of: String)
    end
  end
end

class Chef
  class Provider::JenkinsJNLPSlave < Provider::JenkinsSlave
    def load_current_resource
      @current_resource ||= Resource::JenkinsJNLPSlave.new(new_resource.name)

      super
    end

    #
    # @see Chef::Resource::JenkinsSlave#action_create
    #
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

    #
    # @see Chef::Resource::JenkinsSlave#action_delete
    #
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
      return @jnlp_url if @jnlp_url
      path = ::File.join(
               'computer', new_resource.slave_name, 'slave-agent.jnlp')
      @jnlp_url = URI.join(endpoint, path).to_s
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

    # Embedded Resources

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
        java_bin: java,
        slave_jar: slave_jar,
        jnlp_url: jnlp_url,
        jnlp_secret: jnlp_secret
      )
      @service_resource
    end
  end
end
