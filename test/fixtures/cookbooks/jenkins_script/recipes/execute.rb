include_recipe 'jenkins::master'

# Execute a simple script
jenkins_script 'println("This is Groovy code!")'

# A complex, multi-line scipt
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
