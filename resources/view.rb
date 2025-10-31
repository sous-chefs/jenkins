unified_mode true

resource_name :jenkins_view
provides :jenkins_view

property :jobs, Array, default: []
property :code, String, default: ''

load_current_value do |_new_resource|
  current_view = current_view_from_jenkins

  if current_view && !current_view.empty?
    jobs current_view[:jobs] || []
  else
    current_value_does_not_exist!
  end
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
action :create do
  current_view_jobs = current_resource ? (current_resource.jobs || []) : []

  if current_resource &&
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
action :delete do
  if current_resource
    converge_by("Delete #{new_resource}") do
      executor.execute!('delete-view', escape(new_resource.name))
    end
  else
    Chef::Log.debug("#{new_resource} does not exist - skipping")
  end
end

action_class do
  include Jenkins::Helper

  #
  # The view in a hash format
  #
  # @return [Hash]
  #   Empty hash if the job does not exist, or a hash of important information
  #   if it does
  #
  def current_view_from_jenkins
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
    return if response.nil?

    Chef::Log.debug "Parse #{new_resource} as JSON"
    @current_view = JSON.parse(response, object_class: Mash)
    @current_view
  end
end
