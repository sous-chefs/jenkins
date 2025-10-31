unified_mode true

provides :jenkins_script

property :command, String
property :groovy_path, String

action :execute do
  converge_by("Execute script #{new_resource}") do
    if new_resource.groovy_path
      executor.groovy_from_file!(new_resource.groovy_path)
    else
      executor.groovy!(new_resource.command)
    end
  end
end

action_class do
  include Jenkins::Helper
end
