config = File.join(Chef::Config[:file_cache_path], 'simple-execute.xml')

# Test basic job creation
jenkins_job 'enable-simple-execute' do
  config config
  action :create
end

jenkins_job 'enable-simple-execute' do
  action :disable
end

# Test basic job enablement
jenkins_job 'enable-simple-execute' do
  action :enable
end

# Should do nothing
jenkins_job 'simple-execute' do
  action :enable
end
