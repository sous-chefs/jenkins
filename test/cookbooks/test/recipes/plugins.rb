# Test plugin installation
# For now, just use the default suite which has anonymous read enabled
include_recipe 'test::default'

# Install some common plugins
# These will work because they're downloaded directly to the plugins directory
%w(
  mailer
  credentials
  matrix-auth
).each do |plugin|
  jenkins_plugin plugin
end

# Restart Jenkins once after all plugins are installed
execute 'restart jenkins after plugin installation' do
  command 'systemctl restart jenkins'
  action :run
end
