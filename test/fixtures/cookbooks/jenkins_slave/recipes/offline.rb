include_recipe 'jenkins::master'

# Include the create recipe so we have something to take offline
include_recipe 'jenkins_slave::create'

%w(builder executor smoke).each do |name|
  jenkins_slave name do
    offline_reason "Autobots beat #{name}"
    action :offline
  end
end
