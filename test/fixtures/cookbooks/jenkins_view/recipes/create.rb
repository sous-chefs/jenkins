include_recipe 'jenkins::master'

# Test basic view creation
jenkins_view 'test1'

# Test view creation with attributes
jenkins_view 'test2' do
  regex 'test2.*'
end