include_recipe 'jenkins_server_wrapper::default'

# Test basic plugin installation
jenkins_plugin 'greenballs'

# Test installing a specific version
jenkins_plugin 'disk-usage' do
  version '0.23'
end

# Test installing from a URL
jenkins_plugin 'copy-to-slave' do
  source 'http://mirror.xmission.com/jenkins/plugins/copy-to-slave/1.4.3/copy-to-slave.hpi'
end

# Install a plugin with many deps
jenkins_plugin 'github-oauth' do
  install_deps true
end

# Skip this plugins deps
jenkins_plugin 'jquery-ui' do
  install_deps false
end

# Install with a wacky version number
jenkins_plugin 'build-monitor-plugin' do
  version '1.6+build.135'
  install_deps true
  notifies :restart, 'service[jenkins]', :immediately
end
