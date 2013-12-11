include_recipe 'jenkins::server'

# Create a simple user
jenkins_user 'sethvargo'

# Delete an existing user
jenkins_user 'sethvargo' do
  action :delete
end

# Delete a non-existent user
jenkins_user 'schisamo' do
  action :delete
end
