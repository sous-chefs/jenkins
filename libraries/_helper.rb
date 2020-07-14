#
# Cookbook:: jenkins
# Library:: helper
#
# Author:: Seth Vargo <sethvargo@gmail.com>
#
# Copyright:: 2013-2019, Chef Software, Inc.
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

require 'net/http'
require 'open-uri'
require 'timeout'
require 'uri'

module Jenkins
  module Helper
    class JenkinsTimeout < Timeout::Error; end

    class JenkinsNotReady < StandardError
      def initialize(endpoint, timeout)
        super <<-EOH
The Jenkins master at `#{endpoint}' did not become ready within #{timeout}
seconds. On large Jenkins instances, you may need to increase the timeout to
#{timeout * 4} seconds. Alternatively, Jenkins may have failed to start.
Jenkins can fail to start if:

  - a configuration file is invalid
  - a plugin is only partially installed
  - a plugin's dependencies are not installed

If this problem persists, check your Jenkins log files.
        EOH
      end
    end

    # Matches Version 4 UUID per RFC 4122
    # Example: 38537014-ec66-49b5-aff2-aed1c19e2989
    UUID_REGEX = /[a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[89aAbB][a-f0-9]{3}-[a-f0-9]{12}/.freeze unless defined?(UUID_REGEX)

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
      ensure_cli_present!

      options = {}.tap do |h|
        h[:cli]      = cli
        h[:java]     = java
        h[:key]      = private_key_path if private_key_given?
        h[:proxy]    = proxy if proxy_given?
        h[:endpoint] = endpoint
        h[:timeout]  = timeout if timeout_given?
        h[:username] = username unless username.nil?
        h[:password] = password unless password.nil?
        h[:jvm_options] = jvm_options unless jvm_options.nil?
        h[:protocol] = protocol unless protocol.nil?
        h[:cli_user] = cli_user unless cli_user.nil?
      end

      Jenkins::Executor.new(options)
    end

    #
    # {URI.join} is a fucking nightmare. It rarely works. Using +File.join+ is
    # cool for URLs, until someone is running on Windows and their URLs use the
    # wrong slashes. This method attempts to cleanly join URI/URL segments into
    # a cleanly normalized URL that the libraries can use when constructing
    # URIs.
    #
    # @param [Array<String>] parts
    #   the list of parts to join
    #
    def uri_join(*parts)
      parts = parts.compact.map(&URI.method(:escape))
      URI.parse(parts.join('/')).normalize.to_s
    end

    #
    # A Groovy snippet that will set the requested local Groovy variable
    # to an instance of the credentials represented by `username`.
    # Returns the Groovy `null` if no credentials are found.
    #
    # @param [String] id
    # @param [String] groovy_variable_name
    # @return [String]
    #
    def credentials_for_id_groovy(id, groovy_variable_name)
      <<-EOH.gsub(/^ {8}/, '')
        import jenkins.model.*
        import com.cloudbees.plugins.credentials.*
        import com.cloudbees.plugins.credentials.common.*
        import com.cloudbees.plugins.credentials.domains.*;

        id_matcher = CredentialsMatchers.withId("#{id}")
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
            id_matcher
          )
      EOH
    end

    #
    # A Groovy snippet that will set the requested local Groovy variable
    # to an instance of the credentials represented by `secret`.
    # Returns the Groovy `null` if no credentials are found.
    #
    # @param [String] secret
    # @param [String] description
    # @param [String] groovy_variable_name
    # @return [String]
    #
    def credentials_for_secret_groovy(secret, description, groovy_variable_name)
      <<-EOH.gsub(/^ {8}/, '')
        import jenkins.model.Jenkins;
        import hudson.util.Secret;
        import com.cloudbees.plugins.credentials.CredentialsProvider
        import org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl;
        import org.jenkinsci.plugins.plaincredentials.StringCredentials;

        available_credentials =
          CredentialsProvider.lookupCredentials(
            StringCredentials.class,
            Jenkins.getInstance(),
            hudson.security.ACL.SYSTEM
          ).findAll({
            it.secret      == new Secret(#{convert_to_groovy(secret)}) &&
            it.description == #{convert_to_groovy(description)}
          })

        #{groovy_variable_name} = available_credentials.size() > 0 ? available_credentials[0] : null
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
        # This is ugly but it ensures any backslashes appear as
        # double-backslashes in the resulting Groovy code.
        val = val.gsub(/\\/, '\\\\\\\\')
        # Escape single quotes
        val = val.gsub(/'/, "\\\\'")
        if val.include?("\n")
          "'''#{val}'''"
        else
          "'#{val}'"
        end
      when Array
        list_members = val.map do |v|
          convert_to_groovy(v)
        end
        "[#{list_members.join(',')}]"
      when Hash
        map_members = val.map do |k, v|
          %("#{k}":#{convert_to_groovy(v)})
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
        v = nil if v.is_a?(String) && v.empty?
        [k, v]
      end
      Hash[mapped_hash]
    end

    #
    # Escape the given value for use on the command line.
    #
    # @param [String] value
    #   the value to escape
    #
    # @return [String]
    #   the escaped value
    #
    def escape(value)
      Shellwords.escape(value)
    end

    #
    # Performs a WMI query using WIN32OLE from the Ruby Stdlib
    #
    # @return [String]
    #
    def wmi_property_from_query(wmi_property, wmi_query)
      require 'win32ole'
      wmi = ::WIN32OLE.connect('winmgmts://')
      result = wmi.ExecQuery(wmi_query)
      return nil unless result.each.count > 0
      result.each.next.send(wmi_property)
    end

    private

    #
    # The path to the private key for the Jenkins master on disk. This method
    # also ensure the private key is written to disk.
    #
    # @return [String]
    #   the path to the private key on disk
    #
    def private_key_path
      node.run_state[:jenkins_private_key_path] ||= begin
        # @todo remove in 3.0.0
        if node['jenkins']['executor']['private_key']
          Chef::Log.warn("Using node['jenkins']['executor']['private_key'] is deprecated!")
          Chef::Log.warn('Persisting sensitive information in node attributes is not recommended.')
          node.run_state[:jenkins_private_key] = node['jenkins']['executor']['private_key']
        end

        content = node.run_state[:jenkins_private_key]
        destination = File.join(Chef::Config[:file_cache_path], 'jenkins-key')

        file = Chef::Resource::File.new(destination, run_context)
        file.content(content)
        file.backup(false)
        file.mode('0600')
        # Setting sensitive so the contents of the private key file aren't included in the log.
        # This functionality is not available in older versions of Chef, so check before we use it.
        file.sensitive(true) if file.respond_to?(:sensitive)
        file.run_action(:create)

        destination
      end
    end

    #
    # Boolean method to determine if a private key was supplied.
    #
    # @return [Boolean]
    #
    def private_key_given?
      # @todo remove in 3.0.0
      !node['jenkins']['executor']['private_key'].nil? ||
        !node.run_state[:jenkins_private_key].nil?
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
      !node['jenkins']['executor']['proxy'].nil?
    end

    #
    # The URL endpoint for the Jenkins master.
    #
    # @return [String]
    #
    def endpoint
      node['jenkins']['master']['endpoint']
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
    # Boolean method to determine if proxy timeout was supplied.
    #
    # @return [Boolean]
    #
    def timeout_given?
      !node['jenkins']['executor']['timeout'].nil?
    end

    # Username used when invoking cli
    #
    # @return [String]
    #
    def username
      node.run_state[:jenkins_username]
    end

    #
    # password used when invoking cli
    #
    # @return [String]
    #
    def password
      node.run_state[:jenkins_password]
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
    # JVM options to pass into the cli command call
    #
    # @return [String]
    #
    def jvm_options
      node['jenkins']['executor']['jvm_options']
    end

    #
    # protocol to pass to cli
    # ssh/http/remoting
    #
    # @return [String]
    #
    def protocol
      node['jenkins']['executor']['protocol']
    end

    #
    # CLI user to pass to cli
    # ssh protocol or http protocol needs it
    #
    # @return [String]
    #
    def cli_user
      node['jenkins']['executor']['cli_user']
    end

    #
    # The path to the +jenkins-cli.jar+ on disk (which may or may not exist).
    #
    # @return [String]
    #
    def cli
      File.join(Chef::Config[:file_cache_path], 'jenkins-cli.jar')
    end

    #
    # The path to the +update-center.json+ on disk (which may or may not exist).
    # The file contains all plugins from the jenkins update-center.
    #
    # @return [String]
    #
    def update_center_json
      File.join(Chef::Config[:file_cache_path], 'update-center.json')
    end

    #
    # The path to the fully-extracted, raw JSON structure contained in Jenkin's
    # +update-center.json+. This is the universe of Jenkin's plugins is used
    # by the +jenkins_plugin+ resoure.
    #
    # @return [String]
    #
    def extracted_update_center_json
      File.join(Chef::Config[:file_cache_path], 'extracted-update-center.json')
    end

    #
    # Since the Jenkins service returns immediately and the actual Java process
    # is started in the background, we block the Chef Client run until the
    # service endpoint(s) are _actually_ ready to accept requests.
    #
    # This method will effectively "block" the current thread until the Jenkins
    # master is ready to accept CLI and HTTP requests.
    #
    # @raise [JenkinsNotReady]
    #   if the Jenkins master does not respond within (+timeout+) seconds
    #
    def wait_until_ready!
      Timeout.timeout(timeout, JenkinsTimeout) do
        begin
          open("#{endpoint}/whoAmI/")
        rescue SocketError,
               Errno::ECONNREFUSED,
               Errno::ECONNRESET,
               Errno::ENETUNREACH,
               Errno::EADDRNOTAVAIL,
               Timeout::Error,
               OpenURI::HTTPError => e
          # If authentication has been enabled, the server will return an HTTP
          # 403. This is "OK", since it means that the server is actually
          # ready to accept requests.
          return if e.message =~ /^403/

          Chef::Log.debug("Jenkins is not accepting requests - #{e.message}")
          sleep(0.5)
          retry
        end
      end
    rescue JenkinsTimeout
      raise JenkinsNotReady.new(endpoint, timeout)
    end

    #
    # Idempotently download the remote +jenkins-cli.jar+ file for the Jenkins
    # master. This method will raise an exception if the Jenkins master is
    # unavailable or is not accepting requests.
    #
    def ensure_cli_present!
      node.run_state[:jenkins_cli_present] ||= begin
        source = uri_join(endpoint, 'jnlpJars', 'jenkins-cli.jar')
        remote_file = Chef::Resource::RemoteFile.new(cli, run_context)
        remote_file.source(source)
        remote_file.backup(false)
        remote_file.mode('0755')
        remote_file.run_action(:create)

        true
      end
    end

    #
    # Idempotently download the remote +update-center.json+ file for the Jenkins
    # server. This is needed to be able to install plugins through the update-center.
    #
    def ensure_update_center_present!
      node.run_state[:jenkins_update_center_present] ||= begin
        source = uri_join(node['jenkins']['master']['mirror'], node['jenkins']['master']['channel'], 'update-center.json')
        remote_file = Chef::Resource::RemoteFile.new(update_center_json, run_context)
        remote_file.source(source)
        remote_file.backup(false)

        # Setting sensitive(true) will suppress the long diff output, but this
        # functionality is not available in older versions of Chef, so we need
        # check if the resource responds to the method before calling it.
        remote_file.sensitive(true) if remote_file.respond_to?(:sensitive)
        remote_file.mode('0644')
        remote_file.run_action(:create)

        extracted_json = ''

        # The downloaded file is composed of 3 lines. The first and the last line
        # are containing some javascript, the line in between contains the relevant
        # JSON data. That is the one that must be extracted.
        IO.readlines(update_center_json).map do |line|
          extracted_json << line unless line.include?('updateCenter.post(') || line.include?(');')
        end

        # Write the extracted JSON to a file so `jenkins_plugin` can read it.
        extracted_json_file = Chef::Resource::File.new(extracted_update_center_json, run_context)
        extracted_json_file.content(extracted_json)
        extracted_json_file.backup(false)

        # Setting sensitive(true) will suppress the long diff output, but this
        # functionality is not available in older versions of Chef, so we need
        # check if the resource responds to the method before calling it.
        extracted_json_file.sensitive(true) if extracted_json_file.respond_to?(:sensitive)

        extracted_json_file.mode('0644')
        extracted_json_file.run_action(:create)

        # Ensure Jenkins is alive and kicking
        wait_until_ready!

        # Uri where update-center JSON's can be posted to. Jenkins is now aware of the
        # update-center data and can handle the plugin installation through CLI exactly
        # in the same way as through the user interface.
        uri = URI(uri_join(endpoint, 'updateCenter', 'byId', 'default', 'postBack'))
        headers = { 'Accept' => 'application/json' }
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true if uri.scheme == 'https'
        http.post(uri.path, extracted_json, headers)

        true
      end
    end
  end
end
