include_recipe 'jenkins::master'

ruby_block "Save current running pid of jenkins to test for restart" do
  block do
    File.open('/tmp/kitchen/cache/install_no_restart.pid', 'w+') do |file|
      file.write(`pgrep -f /usr/lib/jenkins/jenkins.war`.strip)
    end
  end
end

# Install plugin, don't restart and tell install-plugin to deploy the plugin
jenkins_plugin 'disk-usage' do
  version '0.23'
  restart false
  options ['-deploy']
end
