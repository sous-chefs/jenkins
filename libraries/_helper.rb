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
    # @return [Jenkins::Executor]
    #
    def executor
      ensure_cli_present!

      options = {}.tap do |h|
        h[:cli]   = cli
        h[:java]  = java
        h[:key]   = private_key if private_key_given?
        h[:proxy] = proxy if proxy_given?
        h[:url]   = url
      end

      Jenkins::Executor.new(options)
    end

    private
    #
    # The path to the private key for the Jenkins master on disk. This method
    # also ensure the private key is written to disk.
    #
    # @return [String]
    #
    def private_key
      content = node['jenkins']['cli']['private_key']
      destination = File.join(Chef::Config[:file_cache_path], 'jenkins-key')

      file = Chef::Resource::File.new(destination, run_context)
      file.content(content)
      file.backup(false)
      file.mode('0600')
      file.run_action(:create)

      destination
    end

    #
    # Boolean method to determine if a private key was supplied.
    #
    # @return [Boolean]
    #
    def private_key_given?
      !!node['jenkins']['cli']['private_key']
    end

    #
    # The proxy information.
    #
    # @return [String]
    #
    def proxy
      node['jenkins']['cli']['proxy']
    end

    #
    # Boolean method to determine if proxy information was supplied.
    #
    # @return [Boolean]
    #
    def proxy_given?
      !!node['jenkins']['cli']['proxy']
    end

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
    # The path to the +jenkin-cli.jar+ on disk (which may or may not exist).
    #
    # @return [String]
    #
    def cli
      File.join(Chef::Config[:file_cache_path], 'jenkins-cli.jar')
    end

    #
    # Idempotently download the remote +jenkins-cli.jar+ file for the Jenkins
    # server. This method will raise an exception if the Jenkins master is
    # unavailable or is not accepting requests.
    #
    def ensure_cli_present!
      source = File.join(url, 'jnlpJars', 'jenkins-cli.jar')

      remote_file = Chef::Resource::RemoteFile.new(cli, run_context)
      remote_file.source(source)
      remote_file.backup(false)
      remote_file.mode('0755')
      remote_file.run_action(:create)
    end
  end
end
