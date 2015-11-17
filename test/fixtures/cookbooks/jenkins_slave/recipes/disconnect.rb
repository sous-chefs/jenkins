include_recipe 'jenkins_server_wrapper::default'

# Include the create recipe so we have something to disconnect
include_recipe 'jenkins_slave::create_ssh'

%w(ssh-builder ssh-executor ssh-smoke).each do |name|
  jenkins_slave name do
    action :disconnect
  end
end
