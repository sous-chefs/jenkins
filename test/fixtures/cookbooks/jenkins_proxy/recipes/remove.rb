include_recipe 'jenkins_server_wrapper::default'

# Create a basic proxy configuration
jenkins_proxy '1.2.3.4:5678'

# Remove an existing proxy configuration
jenkins_proxy '1.2.3.4:5678' do
  action :remove
end

# Remove a non-existent proxy configuration
jenkins_proxy '5.6.7.8:9012' do
  action :remove
end
