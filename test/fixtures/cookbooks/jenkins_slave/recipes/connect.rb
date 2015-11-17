include_recipe 'jenkins_server_wrapper::default'

# Include the disconnect recipe so we have something to connect
include_recipe 'jenkins_slave::disconnect'

%w(ssh-builder ssh-executor ssh-smoke).each do |name|
  jenkins_slave name do
    action :connect
  end
end
