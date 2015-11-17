include_recipe 'jenkins_server_wrapper::default'

# Include the disable recipe so we have something to enable
include_recipe 'jenkins_plugin::disable'

# Test basic job deletion
jenkins_plugin 'greenballs' do
  action :enable
end
