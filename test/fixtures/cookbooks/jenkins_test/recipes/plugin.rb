include_recipe 'jenkins::server'

#
# Install action
#
jenkins_plugin 'greenballs'

jenkins_plugin 'greenballs' do
  version '1.3'
end

jenkins_plugin 'greenballs' do
  source 'http://updates.jenkins-ci.org/download/plugins/greenballs/1.10/greenballs.hpi'
end

#
# Disable action
#
jenkins_plugin 'greenballs' do
  action :disable
end

#
# Enable action
#
jenkins_plugin 'greenballs' do
  action :enable
end

#
# Uninstall action
#
jenkins_plugin 'greenballs' do
  action :uninstall
end
