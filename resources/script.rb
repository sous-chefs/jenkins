#
# Cookbook:: jenkins
# Resource:: script
#
# Author:: Seth Vargo <sethvargo@gmail.com>
#
# Copyright:: 2014-2019, Chef Software, Inc.
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
    resource_name :jenkins_script # Still needed for Chef 15 and below
    provides :jenkins_script

    # Chef attributes
    identity_attr :name

    attribute :groovy_path,
      kind_of: String,
      default: nil
    attribute :name,
      kind_of: String,
      name_attribute: true,
      required: false

    # Actions
    actions :execute
    default_action :execute
  end
end

class Chef
  class Provider::JenkinsScript < Provider::JenkinsCommand
    provides :jenkins_script

    def load_current_resource
      if new_resource.groovy_path
        @current_resource ||= Resource::JenkinsScript.new(new_resource.name)
        @current_resource.name(new_resource.name)
        @current_resource.groovy_path(new_resource.groovy_path)
      else
        @current_resource ||= Resource::JenkinsScript.new(new_resource.command)
      end
      super
    end

    action :execute do
      converge_by("Execute script #{new_resource}") do
        if new_resource.groovy_path
          executor.groovy_from_file!(new_resource.groovy_path)
        else
          executor.groovy!(new_resource.command)
        end
      end
    end
  end
end
