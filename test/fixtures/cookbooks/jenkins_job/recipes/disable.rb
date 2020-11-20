config = File.join(Chef::Config[:file_cache_path], 'simple-execute.xml')

# Test basic job creation
jenkins_job 'disable-simple-execute' do
  config config
  action :create
end

# Test basic job disablement
jenkins_job 'disable-simple-execute' do
  action :disable
end
