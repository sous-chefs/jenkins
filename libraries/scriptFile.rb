#
# Cookbook Name:: jenkins
# HWRP:: scriptFile
#
# Author:: Ludovic SMADJA <ludovic.smadja@jalios.com>
#
# Copyright 2014, JALIOS SA.
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
require_relative '_params_validate'

class Chef
  class Resource::JenkinsScriptFile < Resource::JenkinsCommand
    # Chef attributes
    provides :jenkins_scriptFile

    # Set the resource name
    self.resource_name = :jenkins_scriptFile

    # Actions
    actions :execute
    default_action :execute
    
    # Attributes
    attribute :file,
      kind_of: String,
      name_attribute: true
  end
end

class Chef
  class Provider::JenkinsScriptFile < Provider::JenkinsCommand
    def load_current_resource
      @current_resource ||= Resource::JenkinsScriptFile.new(new_resource.file)
      super
    end

    action(:execute) do
      converge_by("Execute script #{new_resource}") do
        executor.groovyFile!(new_resource.file)
      end
    end
  end
end

Chef::Platform.set(
  resource: :jenkins_scriptFile,
  provider: Chef::Provider::JenkinsScriptFile
)
