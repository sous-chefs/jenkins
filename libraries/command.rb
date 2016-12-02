#
# Cookbook:: jenkins
# HWRP:: command
#
# Author:: Seth Vargo <sethvargo@gmail.com>
#
# Copyright:: 2013-2016, Chef Software, Inc.
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

require_relative '_helper'

class Chef
  class Resource::JenkinsCommand < Resource::LWRPBase
    resource_name :jenkins_command

    # Chef attributes
    identity_attr :command

    # Actions
    actions :execute
    default_action :execute

    # Attributes
    attribute :command,
              kind_of: String,
              name_attribute: true
  end
end

class Chef
  class Provider::JenkinsCommand < Provider::LWRPBase
    use_inline_resources
    include Jenkins::Helper

    provides :jenkins_command

    def load_current_resource
      @current_resource ||= Resource::JenkinsCommand.new(new_resource.command)
    end

    #
    # This provider supports why-run mode.
    #
    def whyrun_supported?
      true
    end

    action :execute do
      converge_by("Execute #{new_resource}") do
        executor.execute!(new_resource.command)
      end
    end
  end
end
