include_recipe 'jenkins::server'

# Include the disconnect recipe so we have something to connect
include_recipe 'jenkins_slave::disconnect'

%w{
  starscream
  skywarp
  thundercracker
}.each do |slave_name|

  jenkins_slave slave_name do
    action :connect
  end

end
