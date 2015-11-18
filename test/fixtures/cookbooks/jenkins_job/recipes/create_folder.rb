include_recipe 'jenkins_server_wrapper::default'

# Test creation of a job that has no disabled attribute
# (some jobs like those created by the cloudbees-folder plugin do not have disabled in their XML config)

jenkins_plugin 'cloudbees-folder' do
  notifies :restart, 'service[jenkins]', :immediately
end

config = File.join(Chef::Config[:file_cache_path], 'folder-config.xml')
cookbook_file config

jenkins_job 'my-folder' do
  config config
end
