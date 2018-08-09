include_recipe 'jenkins_server_wrapper::default'

# Test basic plugin installation
jenkins_plugin 'greenballs'

# Test installing a specific version
jenkins_plugin 'disk-usage' do
  version '0.23'
end

# Test installing a specific version with abnormal versioning
jenkins_plugin 'apache-httpcomponents-client-4-api' do
  version '4.5.3-2.0'
end

# Test installing from a URL
jenkins_plugin 'copy-to-slave' do
  source 'http://mirror.xmission.com/jenkins/plugins/copy-to-slave/1.4.3/copy-to-slave.hpi'
end

# Test installing from a URL with checksum
jenkins_plugin 'ansicolor' do
  source 'http://mirror.xmission.com/jenkins/plugins/ansicolor/0.5.2/ansicolor.hpi'
  checksum '726c651a3ac8d080ff4aa5b962dd8b264801b8a3fde027da07fa1be30c709b31'
end

# Test installing from a URL with invalid checksum fails
jenkins_plugin 'timestamper' do
  source 'http://mirror.xmission.com/jenkins/plugins/timestamper/1.8.10/timestamper.hpi'
  checksum 'invalid'
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
