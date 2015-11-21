include_recipe 'jenkins_server_wrapper::default'

# Include the create recipe so we have something to disable
include_recipe 'jenkins_job::create'

# Test basic job disablement
jenkins_job 'simple-execute' do
  action :disable
end
