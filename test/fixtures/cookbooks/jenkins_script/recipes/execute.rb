include_recipe 'jenkins_server_wrapper::default'

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
