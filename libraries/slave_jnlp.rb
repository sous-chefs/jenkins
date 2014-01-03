#
# Cookbook Name:: jenkins
# HWRP:: jnlp_slave
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
  #
  class Resource::JenkinsJNLPSlave < Resource::JenkinsSlave
    provides :jenkins_jnlp_slave

    def initialize(name, run_context = nil)
      super

      # Set the resource name and provider
      @resource_name = :jenkins_jnlp_slave
      @provider = Provider::JenkinsJNLPSlave
    end
  end
end

#
#
#
class Chef
  #
  class Provider::JenkinsJNLPSlave < Provider::JenkinsSlave
    def load_current_resource
      @current_resource ||= Resource::JenkinsJNLPSlave.new(new_resource.name)

      set_base_attributes
    end

    protected

    #
    # @see Chef::Resource::JenkinsSlave#launcher_groovy
    # @see http://javadoc.jenkins-ci.org/hudson/slaves/JNLPLauncher.html
    #
    def launcher_groovy
      'launcher = new hudson.slaves.JNLPLauncher()'
    end
  end
end
