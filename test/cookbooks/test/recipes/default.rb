# Basic Jenkins installation test - no plugins, no auth
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

node.default['jenkins']['java'] = '/usr/bin/java'

# Increase timeout for Jenkins to become ready - first boot takes longer
node.default['jenkins']['executor']['timeout'] = 300

jenkins_install 'default'
