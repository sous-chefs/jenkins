#
# Cookbook Name:: jenkins
# HWRP:: command
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

#
#
#
class Chef
  #
  class Resource::JenkinsCommand < Resource
    identity_attr :command

    def initialize(name, run_context = nil)
      super

      # Set the resource name and provider
      @resource_name = :jenkins_command
      @provider = Provider::JenkinsCommand

      # Set default actions and allowed actions
      @action = :execute
      @allowed_actions.push(:execute)

      # Set the name attribute and default attributes
      @command = name
      @timeout = 30
    end

    def command(arg = nil)
      set_or_return(:command, arg, kind_of: String)
    end

    def timeout(arg = nil)
      set_or_return(:timeout, arg, kind_of: Fixnum)
    end
  end
end

#
#
#
class Chef
  #
  class Provider::JenkinsCommand < Provider
    include Jenkins::Helper

    def load_current_resource
      @current_resource ||= Resource::JenkinsCommand.new(new_resource.command)
      @current_resource.timeout(new_resource.timeout)
    end

    #
    # This provider supports why-run mode.
    #
    def whyrun_supported?
      true
    end

    def action_execute
      converge_by("Execute #{new_resource}") do
        executor.execute!(new_resource.command)
      end
    end
  end
end
