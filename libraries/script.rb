#
# Cookbook Name:: jenkins
# HWRP:: script
#
# Author:: Seth Vargo <sethvargo@gmail.com>
#
# Copyright 2014, Chef Software, Inc.
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

require_relative 'command'

class Chef
  class Resource::JenkinsScript < Resource::JenkinsCommand
    def initialize(name, run_context = nil)
      super

      # Set the resource name and provider
      @resource_name = :jenkins_script
      @provider = Provider::JenkinsScript
    end
  end
end

class Chef
  class Provider::JenkinsScript < Provider::JenkinsCommand
    def load_current_resource
      @current_resource ||= Resource::JenkinsScript.new(new_resource.command)
    end

    def action_execute
      converge_by("Execute script #{new_resource}") do
        executor.groovy!(new_resource.command)
      end
    end
  end
end
