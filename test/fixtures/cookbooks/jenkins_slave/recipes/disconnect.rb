include_recipe 'jenkins::server'

# Include the create recipe so we have something to disconnect
include_recipe 'jenkins_slave::create'

%w[builder executor smoke].each do |name|
  jenkins_slave name do
    action :disconnect
  end
end
