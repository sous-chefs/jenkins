# Secure Jenkins controller baseline
apt_update 'update' if platform_family?('debian')

# Disable EPEL repos for EL10 - the repositories are not fully available yet in Fedora infrastructure
# epel-next-10 returns 404, epel-10 returns 503
if platform_family?('rhel') && node['platform_version'].to_i >= 10
  node.default['yum']['epel']['managed'] = false
  node.default['yum']['epel-next']['managed'] = false
end

# Install Amazon Corretto 21 LTS
# The java cookbook's corretto_install resource supports custom URLs
# This allows us to use Java 21 LTS which is not yet in the cookbook's defaults
corretto_21_version = '21.0.5.11.1'
corretto_install '21' do
  url lazy {
    arch = node['kernel']['machine'] == 'aarch64' ? 'aarch64' : 'x64'
    "https://corretto.aws/downloads/resources/#{corretto_21_version}/amazon-corretto-#{corretto_21_version}-linux-#{arch}.tar.gz"
  }
  full_version corretto_21_version
  java_home lazy {
    arch = node['kernel']['machine'] == 'aarch64' ? 'aarch64' : 'x64'
    "/usr/lib/jvm/java-21-corretto/amazon-corretto-#{corretto_21_version}-linux-#{arch}"
  }
  bin_cmds %w(jar jarsigner java javac javadoc javap jcmd jconsole jdb jdeprscan jdeps jfr jhsdb jimage jinfo jlink jmap jmod jpackage jps jrunscript jshell jstack jstat jstatd keytool rmid rmiregistry serialver)
end

jenkins_install 'default' do
  java '/usr/bin/java'
  endpoint 'http://localhost:8080'
  update_center_sleep 10
end

directory '/var/lib/jenkins/init.groovy.d' do
  owner 'jenkins'
  group 'jenkins'
  mode '0755'
  recursive true
end

file '/var/lib/jenkins/init.groovy.d/setup-security.groovy' do
  content <<~GROOVY
    import hudson.security.FullControlOnceLoggedInAuthorizationStrategy
    import hudson.security.HudsonPrivateSecurityRealm
    import jenkins.model.Jenkins

    def instance = Jenkins.getInstance()
    def realm = new HudsonPrivateSecurityRealm(false)
    instance.setSecurityRealm(realm)

    def admin = realm.getUser('chef') ?: realm.createAccount('chef', 'chefadmin123')
    admin.setFullName('Chef Client')
    admin.save()

    def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
    strategy.setAllowAnonymousRead(false)
    instance.setAuthorizationStrategy(strategy)
    instance.save()
  GROOVY
  owner 'jenkins'
  group 'jenkins'
  mode '0644'
end

execute 'reset systemd rate limit for secure controller' do
  command 'systemctl reset-failed jenkins'
  action :run
end

execute 'restart jenkins with security enabled' do
  command 'systemctl restart jenkins'
  action :run
end

ruby_block 'wait for secured jenkins controller' do
  block do
    require 'net/http'
    require 'uri'

    ready = false

    120.times do
      begin
        response = Net::HTTP.get_response(URI.parse('http://127.0.0.1:8080/login'))
        if %w(200 403).include?(response.code)
          ready = true
          break
        end
      rescue StandardError => e
        Chef::Log.debug("Waiting for Jenkins security bootstrap: #{e.message}")
      end

      sleep 2
    end

    raise 'Jenkins did not become reachable after security bootstrap' unless ready
  end
end
