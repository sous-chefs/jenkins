include_recipe 'jenkins::server'

# Test basic plugin installation
jenkins_plugin 'greenballs'

# Test installing a specific version
jenkins_plugin 'disk-usage' do
  version '0.23'
end

# Test installing from a URL
jenkins_plugin 'copy-to-slave' do
  source 'http://updates.jenkins-ci.org/download/plugins/copy-to-slave/1.4.3/copy-to-slave.hpi'
end
