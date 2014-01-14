include_recipe 'jenkins::master'

# Include the create recipe so we have something to delete
include_recipe 'jenkins_job::create'

# Test basic job deletion
jenkins_job 'my-project' do
  action :disable
end
