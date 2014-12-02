#
# Cookbook Name:: jenkins
# Library:: executor
#
# Author:: Seth Vargo <sethvargo@gmail.com>
#
# Copyright 2013-2014, Chef Software, Inc.
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

require 'mixlib/shellout'
require 'shellwords'
require 'tempfile'
require 'uri'

module Jenkins
  class Executor
    #
    # The list of options passed to the executor.
    #
    # @return [Hash]
    #
    attr_reader :options

    #
    # Create a new Jenkins executor.
    #
    # @param [Hash] options
    #
    # @option options [String] :endpoint
    #   the endpoint for the Jenkins master
    # @option options [String] :cli
    #   the full path to the Jenkins CLI jar (default:
    #   +/usr/share/jenkins/cli/java/cli.jar+)
    # @option options [String] :java
    #   the full path to the java executable on the system (default: +java+)
    #
    # @return [Jenkins::Executor]
    #
    def initialize(options = {})
      @options = {
        cli:     '/usr/share/jenkins/cli/java/cli.jar',
        java:    'java',
        timeout: 60,
      }.merge(options)
    end

    #
    # Run the given command string against the executor, raising any
    # exceptions to the main thread.
    #
    # @param [Array] pieces
    #   an array of commands to execute
    #
    # @return [String]
    #   the standard out from the command
    #
    def execute!(*pieces)
      command_options = pieces.last.is_a?(Hash) ? pieces.pop : {}
      command = []
      command << %Q("#{options[:java]}")
      command << %Q(-jar "#{options[:cli]}")
      command << %Q(-s #{URI.escape(options[:endpoint])}) if options[:endpoint]
      command << %Q(-i "#{options[:key]}")                if options[:key]
      command << %Q(-p #{uri_escape(options[:proxy])})    if options[:proxy]
      command.push(pieces)

      begin
        cmd = Mixlib::ShellOut.new(command.join(' '), command_options.merge(timeout: options[:timeout]))
        cmd.run_command
        cmd.error!
        cmd.stdout.strip
      rescue Mixlib::ShellOut::ShellCommandFailed
        exitstatus = cmd.exitstatus
        stderr = cmd.stderr
        # We'll fall back to executing the command without authentication if the
        # command fails in a very specific way. This is a sign the provided
        # private key is unknown to the Jenkins master. This exception is commonly
        # thrown the first time a Chef run enables authentication on the Jenkins
        # master. This should also fix some cases of JENKINS-22346.
        if ((exitstatus == 255) && (stderr =~ /^Authentication failed\. No private key accepted\.$/)) ||
          ((exitstatus == 1) && (stderr =~ /^Exception in thread "main" java\.io\.EOFException/))
          command.reject! {|c| c =~ /-i/}
          retry
        end
        raise
      end
    end

    #
    # Same as {Executor#execute!}, but quietly returns +nil+ if the command fails.
    #
    # @see execute!
    #
    def execute(*pieces)
      execute!(*pieces)
    rescue Mixlib::ShellOut::ShellCommandFailed,
           Mixlib::ShellOut::CommandTimeout
      nil
    end

    #
    # Execute the given inline groovy script, raising exceptions if something
    # fails.
    #
    # @param [String] script
    #   the script to run
    #
    # @return [String]
    #   the standard out from the command
    #
    def groovy!(script)
      file = Tempfile.new('groovy')
      file.write script
      file.flush
      execute!("groovy #{file.path}")
    ensure
      file.close! if file
    end

    #
    # Same as {Executor#groovy!}, but quietly returns +nil+ if the command fails.
    #
    # @see groovy!
    #
    def groovy(script)
      file = Tempfile.new('groovy')
      file.write script
      file.flush
      execute("groovy #{file.path}")
    ensure
      file.close! if file
    end

    private

    #
    # Escape the given string for use on the command line.
    #
    # @param [String] string
    #
    # @return [String]
    #
    def shl_escape(string)
      return string if string.length <= 2 # Account for < and <<
      Shellwords.escape(string)
    end

    #
    # Escape the given string as a URI.
    #
    # @param [String] string
    #
    # @return [String]
    #
    def uri_escape(string)
      URI.escape(string)
    end
  end
end
