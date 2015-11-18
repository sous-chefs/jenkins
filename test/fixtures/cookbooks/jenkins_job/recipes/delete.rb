include_recipe 'jenkins_server_wrapper::default'

# Include the create recipe so we have something to delete
include_recipe 'jenkins_job::create'

# Test basic job deletion
jenkins_job 'simple-execute' do
  action :delete
end

# Make sure it ignores non-existent jobs
jenkins_job 'non-existent-project' do
  action :delete
end
