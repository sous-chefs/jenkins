#
# Cookbook Name:: jenkins
# Library:: helper
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

module Jenkins
  module Helper
    #
    # Helper method for creating an accessing a new {Jenkins::Executor} from
    # the node object. Since the {Jenkins::Executor} is a pure Ruby class and
    # works without Chef entirely, this method just pulls the important
    # information from the +node+ object (which is available because )
    #
    def executor
      url  = 'http://0.0.0.0:8080'
      java = 'java'
      cli  = '/var/lib/jenkins/jenkins-cli.jar'

      @exector ||= Jenkins::Executor.new(
        url:  url,
        java: java,
        cli:  cli,
      )
    end

    private

    #
    # The URL for the Jenkins server.
    #
    # @return [String]
    #
    def url
      node['jenkins']['server']['url']
    end

    #
    # The path to the java binary.
    #
    # @return [String]
    #
    def java
      home = node['jenkins']['java_home'] || (node['java'] && node['java']['java_home'])
      home.nil? ? 'java' : File.join(home, 'bin', 'java')
    end

    #
    #
    #
    def cli
      File.join(node['jenkins']['node']['home'], 'jenkins-cli.jar')
    end
  end
end
