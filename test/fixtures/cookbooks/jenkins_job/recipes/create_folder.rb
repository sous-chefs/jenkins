include_recipe 'jenkins::master'

# Test creation of a job that has no disabled attribute
# (some jobs like those created by the cloudbees-folder plugin do not have disabled in their XML config)

jenkins_plugin 'cloudbees-folder' do
    notifies :restart, 'service[jenkins]', :immediately
end

config = File.join(Chef::Config[:file_cache_path], 'folder-config.xml')
template(config) { source 'folder/config.xml.erb' }
jenkins_job 'my-folder' do
  config config
end
