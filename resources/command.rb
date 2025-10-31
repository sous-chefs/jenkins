unified_mode true

provides :jenkins_command

property :command, String, name_property: true

action :execute do
  converge_by("Execute #{new_resource}") do
    executor.execute!(new_resource.command)
  end
end

action_class do
  include Jenkins::Helper
end
