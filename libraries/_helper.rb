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

require 'open-uri'
require 'timeout'

module Jenkins
  module Helper
    class JenkinsNotReady < StandardError
      def initialize(endpoint, timeout)
        super "The Jenkins server at `#{endpoint}' did not become ready " \
              "within #{timeout} seconds. On large Jenkins instances, you " \
              "may need to increase the timeout to #{timeout * 4} seconds. " \
              "Alternatively, Jenkins can fail to start if:\n" \
              "\n" \
              "  - a configuration file is invalid\n" \
              "  - a plugin is partially installed\n" \
              "  - a plugin's dependencies are not installed\n" \
              "\n" \
              "If this problem persists, check your server's log files for " \
              "more information."
      end
    end

    # Matches Version 4 UUID per RFC 4122
    # Example: 38537014-ec66-49b5-aff2-aed1c19e2989
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
      wait_until_ready!
      ensure_cli_present! unless ::File.exists?(cli)

      options = {}.tap do |h|
        h[:cli]      = cli
        h[:java]     = java
        h[:key]      = private_key if private_key_given?
        h[:proxy]    = proxy if proxy_given?
        h[:endpoint] = endpoint
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
        available_credentials =
          CredentialsProvider.lookupCredentials(
            StandardUsernameCredentials.class,
            Jenkins.getInstance(),
            hudson.security.ACL.SYSTEM,
            new SchemeRequirement("ssh")
          )

        #{groovy_variable_name} =
          CredentialsMatchers.firstOrNull(
            available_credentials,
            username_matcher
          )
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

    #
    # Helper which given a Hash converts any blank string values to nil. This
    # is useful in Ruby -> Groovy -> Jenkins conversion where values that are
    # serialized as nil/null are sometimes converted to empty strings.
    #
    # @param [Hash] hash
    # @return [Hash]
    #
    def convert_blank_values_to_nil(hash)
      mapped_hash = hash.dup.map do |k, v|
        v = nil if v.kind_of?(String) && v.empty?
        [k, v]
      end
      Hash[mapped_hash]
    end

    private

    #
    # The path to the private key for the Jenkins master on disk. This method
    # also ensure the private key is written to disk.
    #
    # @return [String]
    #
    def private_key
      content = node['jenkins']['executor']['private_key']
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
      !!node['jenkins']['executor']['private_key']
    end

    #
    # The proxy information.
    #
    # @return [String]
    #
    def proxy
      node['jenkins']['executor']['proxy']
    end

    #
    # Boolean method to determine if proxy information was supplied.
    #
    # @return [Boolean]
    #
    def proxy_given?
      !!node['jenkins']['executor']['proxy']
    end

    #
    # The URL endpoint for the Jenkins server.
    #
    # @return [String]
    #
    def endpoint
      node['jenkins']['server']['endpoint']
    end

    #
    # The global timeout for the executor.
    #
    # @return [Fixnum]
    #
    def timeout
      node['jenkins']['executor']['timeout']
    end

    #
    # The path to the java binary.
    #
    # @return [String]
    #
    def java
      node['jenkins']['java']
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
    # Since the Jenkins service returns immediately and the actual Java process
    # is started in the background, we block the Chef Client run until the
    # service endpoint(s) are _actually_ ready to accept requests.
    #
    # This method will effectively "block" the current thread until the Jenkins
    # server is ready to accept CLI and HTTP requests.
    #
    # @raise [JenkinsNotReady]
    #   if the server does not respond within (+timeout+) seconds
    #
    def wait_until_ready!
      Timeout.timeout(timeout) do
        begin
          open(endpoint)
        rescue SocketError,
               Errno::ECONNREFUSED,
               Errno::ECONNRESET,
               OpenURI::HTTPError => e
          Chef::Log.debug("Jenkins is not accepting requests - #{e.message}")

          sleep(0.5)
          retry
        end
      end
    rescue Timeout::Error
      raise JenkinsNotReady.new(endpoint, timeout)
    end

    #
    # Idempotently download the remote +jenkins-cli.jar+ file for the Jenkins
    # server. This method will raise an exception if the Jenkins master is
    # unavailable or is not accepting requests.
    #
    def ensure_cli_present!
      source = File.join(endpoint, 'jnlpJars', 'jenkins-cli.jar')

      remote_file = Chef::Resource::RemoteFile.new(cli, run_context)
      remote_file.source(source)
      remote_file.backup(false)
      remote_file.mode('0755')
      remote_file.run_action(:create)
    end
  end
end
