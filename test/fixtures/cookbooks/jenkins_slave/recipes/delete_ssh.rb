include_recipe 'jenkins_server_wrapper::default'

# Include the create recipe so we have something to delete
include_recipe 'jenkins_slave::create_ssh'

%w(ssh-builder ssh-executor ssh-smoke).each do |name|
  jenkins_ssh_slave name do
    action :delete
  end
end
