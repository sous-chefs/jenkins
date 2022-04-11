config = File.join(Chef::Config[:file_cache_path], 'simple-execute.xml')

# Test basic job creation
jenkins_job 'delete-simple-execute' do
  config config
  action :create
end

# Test basic job deletion
jenkins_job 'delete-simple-execute' do
  action :delete
end

# Make sure it ignores non-existent jobs
jenkins_job 'non-existent-project' do
  action :delete
end
