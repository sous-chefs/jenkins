# Test basic job deletion
jenkins_plugin 'confluence-publisher' do
  action :uninstall
  notifies :restart, 'service[jenkins]', :immediately
end

# Make sure it ignores non-existent jobs
jenkins_plugin 'non-existent-plugin' do
  action :uninstall
end
