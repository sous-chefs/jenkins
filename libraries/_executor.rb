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
        cli:  '/usr/share/jenkins/cli/java/cli.jar',
        java: 'java',
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
      command =  "#{Shelllwords.escape(options[:java])}"
      command << " -jar #{Shellwords.escape(options[:cli])}"
      command << " -s #{URI.escape(options[:endpoint])}" if options[:endpoint]
      command << " -i #{shl_escape(options[:key])}"      if options[:key]
      command << " -p #{uri_escape(options[:proxy])}"    if options[:proxy]
      command << " #{pieces.join(' ')}"

      command = Mixlib::ShellOut.new(command, timeout: 30)
      command.run_command
      command.error!
      command.stdout.strip
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
      execute!("groovy = <<-GROOVY_SCRIPT\n#{script}\nGROOVY_SCRIPT")
    end

    #
    # Same as {Executor#groovy!}, but quietly returns +nil+ if the command fails.
    #
    # @see groovy!
    #
    def groovy(script)
      execute("groovy = <<-GROOVY_SCRIPT\n#{script}\nGROOVY_SCRIPT")
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
