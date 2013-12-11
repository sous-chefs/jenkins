include_recipe 'jenkins::server'

# Test basic user creation
jenkins_user 'sethvargo'

# Test user creation with attributes
jenkins_user 'schisamo' do
  full_name   'Seth Chisamore'
  email       'schisamo@getchef.com'
  public_keys ['ssh-rsa AAAAAAA']
end
