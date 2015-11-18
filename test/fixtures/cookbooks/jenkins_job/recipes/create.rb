include_recipe 'jenkins_server_wrapper::default'

config = File.join(Chef::Config[:file_cache_path], 'simple-execute.xml')
cookbook_file config

# Test basic job creation
jenkins_job 'simple-execute' do
  config config
  action :create
end
