include_recipe 'jenkins_server_wrapper::default'

# Include the install recipe so we have something to uninstall
include_recipe 'jenkins_plugin::install'

# Grr...
jenkins_command 'restart'

# Test basic job deletion
jenkins_plugin 'greenballs' do
  action :uninstall
end

# Make sure it ignores non-existent jobs
jenkins_plugin 'non-existent-plugin' do
  action :uninstall
end
