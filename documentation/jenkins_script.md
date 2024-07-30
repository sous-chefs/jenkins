# jenkins_script

This resource executes arbitrary Java or Groovy commands against the Jenkins master. By the nature of this command, it is **not** idempotent.

## Examples

A simple inline Groovy script

```ruby
jenkins_script 'println("This is Groovy code!")'
```

More complex inline Groovy

```ruby
jenkins_script 'add_authentication' do
  command <<-EOH.gsub(/^ {4}/, '')
    import jenkins.model.*
    import hudson.security.*
    import org.jenkinsci.plugins.*

    def instance = Jenkins.getInstance()

    def githubRealm = new GithubSecurityRealm(
      'https://github.com',
      'https://api.github.com',
      'API_KEY',
      'API_SECRET'
    )
    instance.setSecurityRealm(githubRealm)

    def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
    instance.setAuthorizationStrategy(strategy)

    instance.save()
  EOH
end
```

Executing Groovy code on disk

```ruby
template ::File.join(Chef::Config[:file_cache_path], 'create_jenkins_user' + '.groovy') do
  source "create_jenkins_user.groovy.erb"
  mode '0644'
  owner 'jenkins'
  group 'jenkins'
  variables(
    users: users
  )
  notifies :execute, "jenkins_script[create_jenkins_user]", :immediately
end

jenkins_script 'create_jenkins_user' do
  groovy_path ::File.join(Chef::Config[:file_cache_path], 'create_jenkins_user' + '.groovy')
end
```
