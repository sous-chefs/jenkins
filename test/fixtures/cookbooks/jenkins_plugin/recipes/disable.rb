include_recipe 'jenkins_server_wrapper::default'

# Include the install recipe so we have something to disable
include_recipe 'jenkins_plugin::install'

# Grr...
jenkins_command 'restart'

# Test basic job deletion
jenkins_plugin 'greenballs' do
  action :disable
end
