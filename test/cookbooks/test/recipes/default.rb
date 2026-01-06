# Basic Jenkins installation test - no plugins, no auth
apt_update 'update' if platform_family?('debian')

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

jenkins_install 'default'
