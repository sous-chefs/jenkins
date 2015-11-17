include_recipe 'jenkins_server_wrapper::default'

# Include the create recipe so we have something to delete
include_recipe 'jenkins_job::disable'

# Test basic job deletion
jenkins_job 'my-project' do
  action :enable
end
