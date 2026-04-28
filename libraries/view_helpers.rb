#
# Cookbook:: jenkins
# Library:: view_helpers
#

require_relative '_helper'

module Jenkins
  module ViewHelpers
    include Jenkins::Helper

    #
    # The view in a hash format
    #
    # @return [Hash]
    #   Empty hash if the job does not exist, or a hash of important information
    #   if it does
    #
    def current_view_from_jenkins(resource = view_resource)
      return @current_view if @current_view

      Chef::Log.debug "Load #{resource} view information"

      get_view_as_json =
        <<-GROOVY
          import hudson.model.*
          import jenkins.model.*
          view_name = '#{resource.name}'
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
      return if response.nil?

      Chef::Log.debug "Parse #{resource} as JSON"
      @current_view = JSON.parse(response, object_class: Mash)
      @current_view
    end

    private

    def view_resource
      respond_to?(:new_resource) && new_resource ? new_resource : self
    end
  end
end
