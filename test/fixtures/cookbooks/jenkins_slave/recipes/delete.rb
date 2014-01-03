include_recipe 'jenkins::server'

# Include the create recipe so we have something to delete
include_recipe 'jenkins_slave::create'

%w{
  grimlock
  starscream
  skywarp
  thundercracker
  soundwave
  shrapnel
}.each do |slave_name|

  jenkins_slave slave_name do
    action :delete
  end

end
