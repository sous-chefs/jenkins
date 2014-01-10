include_recipe 'jenkins::master'

# Execute a simple script
jenkins_script 'println("This is Groovy code!")'

# A complex, multi-line scipt
#
# Note: You should use the +jenkins_user+ resource for this, but this is more
# easily testable.
jenkins_script 'create user' do
  command <<-EOH.gsub(/^ {4}/, '')
    user = hudson.model.User.get('sethvargo')
    user.setFullName('Seth Vargo')

    email = new hudson.tasks.Mailer.UserProperty('sethvargo@gmail.com')
    user.addProperty(email)

    user.save()
  EOH
end
