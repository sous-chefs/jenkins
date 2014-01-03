include_recipe 'jenkins::server'

# Include the create recipe so we have something to disconnect
include_recipe 'jenkins_slave::create'

%w{
  starscream
  skywarp
  thundercracker
}.each do |slave_name|

  jenkins_slave slave_name do
    action :disconnect
  end

end
