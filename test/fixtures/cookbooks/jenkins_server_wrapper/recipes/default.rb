include_recipe 'chef-sugar::default'

if docker?
  # Jenkins is already running
  service 'jenkins' do
    start_command   '/usr/bin/sv start jenkins'
    stop_command    '/usr/bin/sv stop jenkins'
    restart_command '/usr/bin/sv restart jenkins'
    status_command  '/usr/bin/sv status jenkins'
    action :restart
  end
else
  include_recipe 'jenkins::java'
  include_recipe 'jenkins::master'
end

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
