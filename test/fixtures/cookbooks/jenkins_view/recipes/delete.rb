include_recipe 'jenkins::master'

# Create a simple view
jenkins_view 'test1'

# Delete the view
jenkins_view 'test1' do
  action :delete
end

# Delete a non-existent user
jenkins_view 'test2' do
  action :delete
end
