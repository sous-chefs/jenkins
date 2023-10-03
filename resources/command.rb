unified_mode true

property :command,
          String,
          name_property: true

include Jenkins::Helper

def load_current_resource
  @current_resource ||= Resource::JenkinsCommand.new(new_resource.command)
end

action :execute do
  converge_by("Execute #{new_resource}") do
    executor.execute!(new_resource.command)
  end
end
