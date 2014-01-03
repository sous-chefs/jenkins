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

    UUID_REGEX = /[a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[89aAbB][a-f0-9]{3}-[a-f0-9]{12}/

    #
    # Helper method for creating an accessing a new {Jenkins::Executor} from
    # the node object. Since the {Jenkins::Executor} is a pure Ruby class and
    # works without Chef entirely, this method just pulls the important
    # information from the +node+ object (which is available because )
    #
    # @return [Jenkins::Executor]
    #
    def executor
      ensure_cli_present! unless ::File.exists?(cli)

      options = {}.tap do |h|
        h[:cli]   = cli
        h[:java]  = java
        h[:key]   = private_key if private_key_given?
        h[:proxy] = proxy if proxy_given?
        h[:url]   = url
      end

      Jenkins::Executor.new(options)
    end

    #
    # A Groovy snippet that will set the requested local Groovy variable
    # to an instance of the credentials represented by `username`.
    # Returns the Groovy `null` if no credentials are found.
    #
    # @param [String] username
    # @param [String] groovy_variable_name
    # @return [String]
    #
    def credentials_for_username_groovy(username, groovy_variable_name)
      <<-EOH.gsub(/ ^{8}/, '')
        import jenkins.model.*
        import com.cloudbees.plugins.credentials.*
        import com.cloudbees.plugins.credentials.common.*
        import com.cloudbees.plugins.credentials.domains.*;

        username_matcher = CredentialsMatchers.withUsername("#{username}")
        available_credentials = CredentialsProvider.lookupCredentials(StandardUsernameCredentials.class,
                                                                      Jenkins.getInstance(),
                                                                      hudson.security.ACL.SYSTEM,
                                                                      new SchemeRequirement("ssh"))

        #{groovy_variable_name} = CredentialsMatchers.firstOrNull(available_credentials,
                                                                  username_matcher)
      EOH
    end

    #
    # Helper method for converting a Ruby value to it's equivalent in
    # Groovy.
    #
    # @return [String]
    #
    def convert_to_groovy(val)
      case val
      when nil
        'null'
      when String
        %Q{"#{val}"}
      when Array
        list_members = val.map do |v|
          convert_to_groovy(v)
        end
        "[#{list_members.join(',')}]"
      when Hash
        map_members = val.map do |k, v|
          %Q("#{k}":#{convert_to_groovy(v)})
        end
        "[#{map_members.join(',')}]"
      else # Integer, TrueClass/FalseClass etc.
        val
      end
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

    #
    # The path to the +slave.jar+ on disk (which may or may not exist).
    #
    # @return [String]
    #
    def slave_jar
      File.join(Chef::Config[:file_cache_path], 'slave.jar')
    end

    #
    # Idempotently download the remote +slave.jar+ file for the Jenkins
    # server. This method will raise an exception if the Jenkins master is
    # unavailable or is not accepting requests.
    #
    def ensure_slave_jar_present!
      source = File.join(url, 'jnlpJars', 'slave.jar')

      remote_file = Chef::Resource::RemoteFile.new(cli, run_context)
      remote_file.source(source)
      remote_file.backup(false)
      remote_file.mode('0755')
      remote_file.run_action(:create)
    end
  end
end
