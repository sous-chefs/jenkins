include_recipe 'jenkins_server_wrapper::default'

# Create and Delete an existing user
jenkins_user 'sethvargo' do
  action [:create, :delete]
end

# Delete a non-existent user
jenkins_user 'schisamo' do
  action :delete
end
