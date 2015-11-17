include_recipe 'jenkins_server_wrapper::default'

# Include the create recipe so we have something to take offline
include_recipe 'jenkins_slave::create_jnlp'

%w(builder executor smoke).each do |name|
  jenkins_slave name do
    offline_reason "Autobots beat #{name}"
    action :offline
  end
end
