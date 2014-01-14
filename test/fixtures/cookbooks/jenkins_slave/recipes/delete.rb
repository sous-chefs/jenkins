include_recipe 'jenkins::master'

# Include the create recipe so we have something to delete
include_recipe 'jenkins_slave::create'

%w[builder executor smoke].each do |name|
  jenkins_jnlp_slave name do
    action :delete
  end
end

%w[ssh-builder ssh-executor ssh-smoke].each do |name|
  jenkins_ssh_slave name do
    action :delete
  end
end
