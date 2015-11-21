include_recipe 'jenkins_server_wrapper::default'

# Include the disable recipe so we have something to enable
include_recipe 'jenkins_job::disable'

# Test basic job enablement
jenkins_job 'simple-execute' do
  action :enable
end
