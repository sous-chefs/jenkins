apt_update 'update' if platform_family?('debian')

adoptopenjdk_install '8' do
  variant 'hotspot'
end

# node[java] is gone, so manually set java path since some platforms need absolute path for service
node.default['jenkins']['java'] = '/usr/bin/java'

include_recipe 'jenkins::master'

# Install some plugins needed, but not installed on jenkins2 by default
# jdk-tool is required by Jenkins version 2.112
jenkins_plugins = %w(
  mailer
  ssh-slaves
  jdk-tool
  display-url-api
  credentials
  matrix-auth
)

jenkins_plugins.each do |plugin|
  jenkins_plugin plugin do
    ignore_deps_versions true
    notifies :execute, 'jenkins_command[safe-restart]', :immediately
  end
end

jenkins_command 'safe-restart' do
  action :nothing
end
