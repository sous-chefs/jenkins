# require_relative 'command'
use 'partials/_command'
unified_mode true

property :groovy_path,
          String

property :name,
          String,
          name_property: true,
          required: false

def load_current_resource
  if new_resource.groovy_path
    @current_resource ||= Resource::JenkinsScript.new(new_resource.name)
    @current_resource.name(new_resource.name)
    @current_resource.groovy_path(new_resource.groovy_path)
  else
    @current_resource ||= Resource::JenkinsScript.new(new_resource.command)
  end
  super
end

action :execute do
  converge_by("Execute script #{new_resource}") do
    if new_resource.groovy_path
      executor.groovy_from_file!(new_resource.groovy_path)
    else
      executor.groovy!(new_resource.command)
    end
  end
end
