include_recipe 'chef-sugar::default'

if docker?
  # Jenkins is already running
  service 'jenkins' do
    start_command   '/usr/bin/sv start jenkins'
    stop_command    '/usr/bin/sv stop jenkins'
    restart_command '/usr/bin/sv restart jenkins'
    status_command  '/usr/bin/sv status jenkins'
    action :nothing
  end
else
  include_recipe 'jenkins::java'
  include_recipe 'jenkins::master'
end
