include_recipe 'jenkins::master'

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

# Test a cold deploy
jenkins_plugin 'gitlab-hook' do
  options '-deploy'
end
