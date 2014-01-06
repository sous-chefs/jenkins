include_recipe 'jenkins::server'

# Include the create recipe so we have something to delete
include_recipe 'jenkins_slave::create'

%w{
  grimlock
  soundwave
  shrapnel
}.each do |slave_name|

  jenkins_jnlp_slave slave_name do
    action :delete
  end

end

%w{
  starscream
  skywarp
  thundercracker
}.each do |slave_name|

  jenkins_ssh_slave slave_name do
    action :delete
  end

end
