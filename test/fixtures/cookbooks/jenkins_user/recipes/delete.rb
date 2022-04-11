# Create a simple user
jenkins_user 'delete-user'

# Delete an existing user
jenkins_user 'delete-user' do
  action :delete
end

# Delete a non-existent user
jenkins_user 'missing-user' do
  action :delete
end
