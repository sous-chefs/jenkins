include_recipe 'jenkins::server'

# Include the offline recipe so we have something to take online
include_recipe 'jenkins_slave::offline'

%w{
  starscream
  skywarp
  thundercracker
}.each do |slave_name|

  jenkins_slave slave_name do
    action :online
  end

end
