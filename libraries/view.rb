#
# Cookbook:: jenkins
# Resource:: view
#
# Author:: Dan Fruehauf <malkodan@gmail.com>
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

require_relative '_helper'
require_relative '_params_validate'

class Chef
  class Resource::JenkinsView < Resource::LWRPBase
    resource_name :jenkins_view # Still needed for Chef 15 and below
    provides :jenkins_view

    # Chef attributes
    identity_attr :name

    # Actions
    actions :create, :delete
    default_action :create

    # Attributes
    attribute :jobs,
              kind_of: Array,
              default: []
    attribute :code,
              kind_of: String,
              default: '',
              required: false

    attr_writer :exists

    #
    # Determine if the view exists on the master. This value is set by the
    # provider when the current resource is loaded.
    #
    # @return [Boolean]
    #
    def exists?
      !@exists.nil? && @exists
    end
  end
end

class Chef
  class Provider::JenkinsView < Provider::LWRPBase
    class ViewDoesNotExist < StandardError
      def initialize(view, action)
        super <<-EOH
The Jenkins view `#{view}' does not exist. In order to #{action} `#{view}', that
view must first exist on the Jenkins master!
        EOH
      end
    end

    include Jenkins::Helper

    provides :jenkins_view

    def load_current_resource
      @current_resource ||= Resource::JenkinsView.new(new_resource.name)
      @current_resource.name(new_resource.name)
      @current_resource.jobs(new_resource.jobs)

      @current_resource.exists = if current_view
                                   true
                                 else
                                   false
                                 end

      @current_resource
    end

    #
    # Idempotently create a new Jenkins view with the current resource's name
    # and given configuration. If the view already exists, update it. If the
    # view does not exist, one will be created from the given # `config` XML
    # file using the Jenkins CLI.
    #
    # If `code` is passed then the view is not necessarily created idempotently
    # as we cannot guarantee what the user has in mind
    #
    action(:create) do
      current_view_jobs = current_view[:jobs]
      current_view_jobs ||= []

      if current_resource.exists? &&
         current_view_jobs == new_resource.jobs &&
         new_resource.code == ''
        Chef::Log.debug("#{new_resource} exists - skipping")
      else
        jobs_to_remove = current_view_jobs - new_resource.jobs
        jobs_to_add    = new_resource.jobs - current_view_jobs

        create_view =
          <<-GROOVY
            import hudson.model.*
            import jenkins.model.*
            def view_name = '#{new_resource.name}'
            def jenkins = Jenkins.instance

            def create_view = { name ->
              return new ListView(name)
            }

            def configure_view = { view ->
              #{jobs_to_remove}.each { view.remove(jenkins.getItem(it)) }
              #{jobs_to_add}.each    { view.add(jenkins.getItem(it)) }
            }

            #{new_resource.code}

            def view = jenkins.getView(view_name)
            if (!view) {
              view = create_view(view_name)
              jenkins.addView(view)
            }
            configure_view(view)

            jenkins.save()
          GROOVY

        converge_by("Create #{new_resource}") do
          executor.groovy!(create_view)
        end
      end
    end

    #
    # Idempotently delete a Jenkins view with the current resource's name. If
    # the view does not exist, no action will be taken. If the view does exist,
    # it will be deleted using the Jenkins CLI.
    #
    action(:delete) do
      if current_resource.exists?
        converge_by("Delete #{new_resource}") do
          executor.execute!('delete-view', escape(new_resource.name))
        end
      else
        Chef::Log.debug("#{new_resource} does not exist - skipping")
      end
    end

    private

    #
    # The view in a hash format
    #
    # @return [Hash]
    #   Empty hash if the job does not exist, or a hash of important information
    #   if it does
    #
    def current_view
      return @current_view if @current_view

      Chef::Log.debug "Load #{new_resource} view information"

      get_view_as_json =
        <<-GROOVY
          import hudson.model.*
          import jenkins.model.*
          view_name = '#{new_resource.name}'
          jenkins = Jenkins.instance

          def view_variables = new groovy.json.JsonBuilder()
          view_variables {}

          // Output view as JSON, easily parse-able by ruby
          view = jenkins.getView(view_name)
          if (view) {
            view_variables {
              name view_name
              jobs view.getItems().collect { it.name }
            }
          }

          println view_variables.toString()
        GROOVY

      response = executor.groovy!(get_view_as_json)
      return nil if response.nil?

      Chef::Log.debug "Parse #{new_resource} as JSON"
      @current_view = JSON.parse(response, object_class: Mash)
      @current_view
    end
  end
end
