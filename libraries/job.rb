#
# Cookbook:: jenkins
# HWRP:: job
#
# Author:: Seth Vargo <sethvargo@gmail.com>
#
# Copyright:: 2013-2017, Chef Software, Inc.
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

require 'rexml/document'

require_relative '_helper'

class Chef
  class Resource::JenkinsJob < Resource::LWRPBase
    resource_name :jenkins_job

    # Chef attributes
    identity_attr :name

    # Actions
    actions :build, :create, :delete, :disable, :enable
    default_action :create

    # Attributes
    attribute :name,
              kind_of: String,
              name_attribute: true
    attribute :config,
              kind_of: String

    # Execute specific attributes
    attribute :parameters,
              kind_of: Hash,
              default: {}
    attribute :stream_job_output,
              kind_of: [TrueClass, FalseClass],
              default: true
    attribute :wait_for_completion,
              kind_of: [TrueClass, FalseClass],
              default: true

    attr_writer :enabled, :exists

    #
    # Determine if the job exists on the master. This value is set by the
    # provider when the current resource is loaded.
    #
    # @return [Boolean]
    #
    def exists?
      !@exists.nil? && @exists
    end

    #
    # Determine if the job is enabled on the master. This value is set by the
    # provider when the current resource is loaded.
    #
    # @return [Boolean]
    #
    def enabled?
      !@enabled.nil? && @enabled
    end
  end
end

class Chef
  class Provider::JenkinsJob < Provider::LWRPBase
    use_inline_resources

    include Jenkins::Helper

    provides :jenkins_job

    # After some careful discussions internally, it was decided that
    # raising an exception when the job does not exist is the best
    # developer experience.
    class JobDoesNotExist < StandardError
      def initialize(job, action)
        super <<-EOH
The Jenkins job `#{job}' does not exist. In order to :#{action} `#{job}', that
job must first exist on the Jenkins master!
EOH
      end
    end

    def load_current_resource
      @current_resource ||= Resource::JenkinsJob.new(new_resource.name)
      @current_resource.name(new_resource.name)
      @current_resource.config(new_resource.config)

      if current_job
        @current_resource.exists  = true
        @current_resource.enabled = current_job[:enabled]
      else
        @current_resource.exists  = false
        @current_resource.enabled = false
      end

      @current_resource
    end

    #
    # This provider supports why-run mode.
    #
    def whyrun_supported?
      true
    end

    #
    # Executes a Jenkins job.
    #
    # @raise [JobDoesNotExist]
    #   if the job does not exist
    #
    action :build do
      unless current_resource.exists?
        raise JobDoesNotExist.new(new_resource.name, :build)
      end

      if current_resource.enabled?
        converge_by("Build #{new_resource}") do
          command_args = [
            'build',
            escape(new_resource.name),
          ]

          if new_resource.wait_for_completion
            command_args << '-s' # Wait until the completion/abortion of the command.
          end

          new_resource.parameters.each_pair do |key, value|
            command_args << "-p #{key}='#{value}'"
          end

          if new_resource.stream_job_output && new_resource.wait_for_completion && stdout_stream
            command_args << '-v' # Prints out the console output of the build.

            stdout_stream.print <<-EOH


================================================================================
= BEGIN '#{new_resource.name}' Jenkins job output
================================================================================

            EOH

            executor.execute!(*command_args, live_stream: stdout_stream)

            stdout_stream.print <<-EOH

================================================================================
= END '#{new_resource.name}' Jenkins job output
================================================================================
            EOH
          else
            executor.execute!(*command_args)
          end
        end
      else
        Chef::Log.info("#{new_resource} disabled - skipping")
      end
    end

    #
    # Idempotently create a new Jenkins job with the current resource's name
    # and configuration file. If the job already exists, no action will be
    # taken. If the job does not exist, one will be created from the given
    # `config` XML file using the Jenkins CLI.
    #
    # This method also ensures the given configuration file matches the one
    # rendered on the Jenkins master. If the configuration file does not match,
    # a new one is rendered.
    #
    # Requirements:
    #   - `config` parameter
    #
    action :create do
      validate_config!

      if current_resource.exists?
        Chef::Log.info("#{new_resource} exists - skipping")
      else
        converge_by("Create #{new_resource}") do
          executor.execute!('create-job', escape(new_resource.name), '<', escape(new_resource.config))
        end
      end

      if correct_config?
        Chef::Log.info("#{new_resource} config up to date - skipping")
      else
        converge_by("Update #{new_resource} config") do
          executor.execute!('update-job', escape(new_resource.name), '<', escape(new_resource.config))
        end
      end
    end

    #
    # Idempotently delete a Jenkins job with the current resource's name. If
    # the job does not exist, no action will be taken. If the job does exist,
    # it will be deleted using the Jenkins CLI.
    #
    action :delete do
      if current_resource.exists?
        converge_by("Delete #{new_resource}") do
          executor.execute!('delete-job', escape(new_resource.name))
        end
      else
        Chef::Log.info("#{new_resource} does not exist - skipping")
      end
    end

    #
    # Disable an existing Jenkins job.
    #
    # @raise [JobDoesNotExist]
    #   if the job does not exist
    #
    action :disable do
      unless current_resource.exists?
        raise JobDoesNotExist.new(new_resource.name, :disable)
      end

      if current_resource.enabled?
        converge_by("Disable #{new_resource}") do
          executor.execute!('disable-job', escape(new_resource.name))
        end
      else
        Chef::Log.info("#{new_resource} disabled - skipping")
      end
    end

    #
    # Enable an existing Jenkins job.
    #
    # @raise [JobDoesNotExist]
    #   if the job does not exist
    #
    action :enable do
      unless current_resource.exists?
        raise JobDoesNotExist.new(new_resource.name, :enable)
      end

      if current_resource.enabled?
        Chef::Log.info("#{new_resource} enabled - skipping")
      else
        converge_by("Enable #{new_resource}") do
          executor.execute!('enable-job', escape(new_resource.name))
        end
      end
    end

    private

    #
    # The job in the current, in XML format.
    #
    # @return [nil, Hash]
    #   nil if the job does not exist, or a hash of important information if
    #   it does
    #
    def current_job
      return @current_job if @current_job

      Chef::Log.debug "Load #{new_resource} job information"

      response = executor.execute('get-job', escape(new_resource.name))
      return nil if response.nil? || response =~ /No such job/

      Chef::Log.debug "Parse #{new_resource} as XML"
      xml = REXML::Document.new(response)
      disabled = xml.elements['//disabled']

      @current_job = {
        enabled: disabled.nil? ? true : disabled.text == 'false',
        xml:     xml,
        raw:     response,
      }
      @current_job
    end

    #
    # Helper method for determining if the given JSON is in sync with the
    # current configuration on the Jenkins master.
    #
    # We have to create REXML objects and then remove any whitespace because
    # XML is evil and sometimes sucks at the simplest things, like comparing
    # itself.
    #
    # @return [Boolean]
    #
    def correct_config?
      current = StringIO.new
      wanted  = StringIO.new

      current_job[:xml].write(current, 2)
      REXML::Document.new(::File.read(new_resource.config)).write(wanted, 2)

      current.string == wanted.string
    end

    #
    # Validate that a configuration file was given as a parameter to the
    # resource. This method also validates the given config file path exists
    # on the target node. Finally, this method reads the contents of the file
    # and verifies it is valid XML.
    #
    def validate_config!
      Chef::Log.debug "Validate #{new_resource} configuration"

      if new_resource.config.nil? # rubocop: disable Style/GuardClause
        raise("#{new_resource} must specify a configuration file!")
      elsif !::File.exist?(new_resource.config)
        raise("#{new_resource} config `#{new_resource.config}` does not exist!")
      else
        begin
          REXML::Document.new(::File.read(new_resource.config))
        rescue REXML::ParseException
          raise("#{new_resource} config `#{new_resource.config}` is not valid XML!")
        end
      end
    end

    # Inspired by chef/chef/#4040
    def formatter?
      if run_context.events.respond_to?(:subscribers)
        run_context.events.subscribers.any? { |s| s.respond_to?(:is_formatter?) && s.is_formatter? }
      else
        false
      end
    end

    def stdout_stream
      @stdout_stream ||= begin
        if formatter?
          Chef::EventDispatch::EventsOutputStream.new(run_context.events, name: new_resource.name.to_sym)
        elsif STDOUT.tty? && !Chef::Config[:daemon]
          STDOUT
        end
      end
    end
  end
end
