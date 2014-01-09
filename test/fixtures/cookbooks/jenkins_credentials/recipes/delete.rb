include_recipe 'jenkins::master'

# Include the create recipe so we have something to delete
include_recipe 'jenkins_credentials::create'

# test deletion with base resource
jenkins_credentials 'schisamo' do
  action :delete
end

# test deletion with `jenkins_password_credentials` child resource
jenkins_password_credentials 'schisamo2' do
  action :delete
end

# test deletion with base resource
jenkins_credentials 'jenkins2' do
  action :delete
end

# test deletion with `jenkins_private_key_credentials` child resource
jenkins_private_key_credentials 'jenkins' do
  action :delete
end
