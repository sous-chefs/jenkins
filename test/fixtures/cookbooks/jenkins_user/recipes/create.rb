include_recipe 'jenkins::master'

# Test basic user creation
jenkins_user 'sethvargo'

# Test user creation with attributes
jenkins_user 'schisamo' do
  full_name   'Seth Chisamore'
  email       'schisamo@getchef.com'
  public_keys ['ssh-rsa AAAAAAA']
end

jenkins_user 'valyukov' do
  full_name 'Vlad Alyukov'
  email   'valyukov@gmail.com'
  password  'test_password'
  public_keys ['ssh-rsa BBBBBBB']
end
