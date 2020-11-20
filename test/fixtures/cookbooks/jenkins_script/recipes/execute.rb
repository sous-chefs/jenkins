# Execute a simple script
jenkins_script 'println("This is Groovy code!")'

# A complex, multi-line scipt
#
# Note: You should use the +jenkins_user+ resource for this, but this is more
# easily testable.
jenkins_script 'create user' do
  command <<-EOH.gsub(/^ {4}/, '')
    user = hudson.model.User.get('yzl')
    user.setFullName('Yvonne Lam')

    email = new hudson.tasks.Mailer.UserProperty('yzl@chef.io')
    user.addProperty(email)

    user.save()
  EOH
end

users = [
  {
    'short_name' => 'badger',
    'full_name' => 'Badger Badger',
    'email' => 'badger@chef.io',
  },
  {
    'short_name' => 'foo',
    'full_name' => 'Foo Foo',
    'email' => 'foo@chef.io',
  },
]

template ::File.join(Chef::Config[:file_cache_path], 'create_jenkins_user' + '.groovy') do
  source 'create_jenkins_user.groovy.erb'
  mode '0644'
  owner 'jenkins'
  group 'jenkins'
  variables(
    users: users
  )
  notifies :execute, 'jenkins_script[create_jenkins_user]', :immediately
end

jenkins_script 'create_jenkins_user' do
  groovy_path ::File.join(Chef::Config[:file_cache_path], 'create_jenkins_user' + '.groovy')
end
