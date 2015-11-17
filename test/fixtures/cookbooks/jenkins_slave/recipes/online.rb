include_recipe 'jenkins_server_wrapper::default'

# Include the offline recipe so we have something to take online
include_recipe 'jenkins_slave::offline'

%w(builder executor smoke).each do |name|
  jenkins_slave name do
    action :online
  end
end
