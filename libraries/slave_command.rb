#
# Cookbook Name:: jenkins
# HWRP:: command_slave
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

require_relative 'slave'

#
#
#
class Chef
  class Resource::JenkinsCommandSlave < Resource::JenkinsSlave
    provides :jenkins_command_slave

    def initialize(name, run_context = nil)
      super

      # Set the resource name and provider
      @resource_name = :jenkins_command_slave
      @provider = Provider::JenkinsCommandSlave
    end

    #
    # Command to execute on the master to start the slave. This assumes
    # the master is capable of remotely executing a process on a slave,
    # such as through ssh/rsh.
    #
    # @param [String] arg
    # @return [String]
    #
    def command(arg = nil)
      set_or_return(:command, arg, kind_of: String)
    end

  end
end

#
#
#
class Chef
  class Provider::JenkinsCommandSlave < Provider::JenkinsSlave
    include Jenkins::Helper

    def load_current_resource
      @current_resource ||= Resource::JenkinsCommandSlave.new(new_resource.name)

      set_base_attributes

      if current_slave
        @current_resource.command(current_slave[:command])
      end
    end

    protected

    #
    # @see Chef::Resource::JenkinsSlave#launcher_groovy
    # @see http://javadoc.jenkins-ci.org/hudson/slaves/CommandLauncher.html
    #
    def launcher_groovy
      <<-EOH.gsub(/ ^{8}/, '')
        launcher = new hudson.slaves.CommandLauncher('#{new_resource.command}',
                                                      #{convert_to_groovy(new_resource.environment)})
      EOH
    end

    #
    # @see Chef::Resource::JenkinsSlave#attribute_to_property_map
    #
    def attribute_to_property_map
      {
        command: 'slave.launcher.command'
      }
    end
  end
end
