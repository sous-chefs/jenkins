apt_update 'update' if platform_family?('debian')

include_recipe 'java::default'
include_recipe 'jenkins::master'

# Install some plugins needed, but not installed on jenkins2 by default
jenkins_plugins = %w(
  mailer
  credentials
  ssh-credentials
  ssh-slaves
)
jenkins_plugins.each do |plugin|
  jenkins_plugin plugin do
    notifies :execute, 'jenkins_command[safe-restart]', :immediately
  end
end

jenkins_command 'safe-restart' do
  action :nothing
end
