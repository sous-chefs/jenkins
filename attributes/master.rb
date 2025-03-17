#
# Cookbook:: jenkins
# Attributes:: master
#
# Author: Doug MacEachern <dougm@vmware.com>
# Author: Fletcher Nichol <fnichol@nichol.ca>
# Author: Seth Chisamore <schisamo@chef.io>
# Author: Seth Vargo <sethvargo@gmail.com>
#
# Copyright:: 2010-2016, VMware, Inc.
# Copyright:: 2012-2019, Chef Software, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

default['jenkins']['master'].tap do |master|
  #
  # The installation method - +package+ or +war+. On RedHat and Debian
  # platforms, the installation method is to use the package from the official
  # Apt/Yum repos. On other platforms, the default method is using the war
  # file.
  #
  #   node.normal['jenkins']['master']['install_method'] = 'war'
  #
  master['install_method'] = platform_family?('debian', 'rhel', 'amazon') ? 'package' : 'war'

  #
  # The version of the Jenkins master to install. This can be a specific
  # package version (from the yum or apt repo), or the version of the war
  # file to download from the Jenkins mirror.
  #
  master['version'] = nil

  #
  # The "channel" to use, default is stable
  # Alternatively: "current" for install method package and "latest" for install method war
  #
  master['channel'] = 'stable'

  #
  # The mirror to download the Jenkins war file. This attribute is only used
  # in the "war" installation method.
  #
  #   node.normal['jenkins']['master']['mirror'] = 'http://cache.example.com'
  #
  # Note: this mirror is combined with some "smart" attributes to build the
  # Jenkins war. If you are not using an actual Jenkins mirror, you might be
  # more interested in the +source+ attribute, which accepts the full path
  # to the war file for downloading.
  #
  master['mirror'] = 'https://updates.jenkins.io'

  #
  # The full URL to the Jenkins WAR file on the remote mirror. This attribute is
  # only used in the "war" installation method. This is a compiled attribute
  # from the +mirror+ and +version+ attributes, but you can override this
  # attribute and specify the full URL path to a remote file for the Jenkins
  # war file. If you choose to override this file manually, it is highly
  # recommended that you also set the +checksum+ attribute.
  #
  #   node.normal['jenkins']['master']['source'] = 'http://fs01.example.com/jenkins.war'
  #
  # Warning: Setting this attribute will negate/ignore any values for +mirror+
  # and +version+.
  #
  master['source'] = "#{node['jenkins']['master']['mirror']}/"\
    "#{node['jenkins']['master']['version'] || node['jenkins']['master']['channel']}/"\
    'latest/jenkins.war'

  #
  # The checksum of the war file. This is use to verify that the remote war file
  # has not been tampered with (such as a MITM attack). If you leave this #
  # attribute set to +nil+, no validation will be performed. If this attribute
  # is set to the wrong SHA-256 checksum, the Chef Client run will fail.
  #
  #   node.normal['jenkins']['master']['checksum'] = 'abcd1234...'
  #
  master['checksum'] = nil

  #
  # The list of options to pass to the Java JVM script when using the package
  # installer. For example:
  #
  #   node.normal['jenkins']['master']['jvm_options'] = '-Xmx256m'
  #
  master['jvm_options'] = '-Djenkins.install.runSetupWizard=false'

  #
  # The list of Jenkins arguments to pass to the initialize script. This varies
  # from system-to-system, but here are some examples:
  #
  #   --javahome=$JAVA_HOME
  #   --httpPort=$HTTP_PORT (default 8080; disable with -1)
  #   --httpsPort=$HTTP_PORT
  #   --ajp13Port=$AJP_PORT
  #   --argumentsRealm.passwd.$ADMIN_USER=[password]
  #   --argumentsRealm.roles.$ADMIN_USER=admin
  #   --webroot=~/.jenkins/war
  #   --prefix=$PREFIX
  #
  # This attribute is _cumulative_, meaning it is appended to the end of the
  # existing environment variable.
  #
  #   node.normal['jenkins']['master']['jenkins_args'] = '--argumentsRealm.roles.$ADMIN_USER=admin'
  #
  master['jenkins_args'] = nil

  #
  # The username of the user who will own and run the Jenkins process. You can
  # change this to any user on the system. Chef will automatically create the
  # user if it does not exist.
  #
  #   node.normal['jenkins']['master']['user'] = 'root'
  #
  master['user'] = 'jenkins'

  #
  # The group under which Jenkins is running. Jenkins doesn't actually use or
  # honor this attribute - it is used for file permission purposes.
  #
  master['group'] = 'jenkins'

  #
  # Directory mode for Jenkins directories.
  #
  master['mode'] = '0755'

  #
  # Jenkins user/group should be created as `system` accounts for `war` install.
  # The default of `true` will ensure that **new** jenkins user accounts are
  # created in the system ID range, existing users will not be modified.
  #
  #   node.normal['jenkins']['master']['use_system_accounts'] = false
  #
  master['use_system_accounts'] = true

  #
  # The host the Jenkins master is running on. For single-installs, the default
  # value of +localhost+ will suffice. For multi-node installs, you will likely
  # need to update this attribute to the FQDN of your Jenkins master.
  #
  # If you are running behind a proxy, please see the documentation for the
  # +endpoint+ attribute instead.
  #
  master['host'] = 'localhost'

  #
  # The address bound to the Jenkins process. The default value binds to all interfaces.
  #
  master['listen_address'] = '0.0.0.0'

  #
  # Ajp13 Port Jenkins is listening on. Set to -1 to disable
  #
  master['ajp_port'] = case node['platform_family']
                       when 'debian'
                         -1
                       when 'rhel', 'amazon'
                         8009
                       end

  #
  # Debug level for logs. The higher the value, the more verbose. 5 is INFO.
  #
  master['debug_level'] = 5

  #
  # Maximum number of HTTP worker threads.
  #
  master['handler_max'] = 100

  #
  # Maximum number of idle HTTP worker threads.
  #
  master['handler_idle'] = 20

  #
  # The port which the Jenkins process will listen on.
  #
  master['port'] = 8080

  #
  # The top-level endpoint for the Jenkins master. By default, this is a
  # "compiled" attribute from +jenkins.master.host+ and +jenkins.master.port+,
  # but you will need to change this attribute if you choose to serve Jenkins
  # behind an HTTP(s) proxy. For example, if you have an Nginx proxy that runs
  # Jenkins on port 80 on a custom domain with a proxy, you will need to set
  # that attribute here:
  #
  #   node.normal['jenkins']['master']['endpoint'] = 'https://custom.domain.com/jenkins'
  #
  master['endpoint'] = "http://#{node['jenkins']['master']['host']}:#{node['jenkins']['master']['port']}"

  #
  # The path to the Jenkins home location. This will also become the value of
  # +$JENKINS_HOME+. By default, this is the directory where Jenkins stores its
  # configuration and build artifacts. You should ensure this directory resides
  # on a volume with adequate disk space.
  #
  master['home'] = '/var/lib/jenkins'

  #
  # The directory where Jenkins should write its logfile(s). **This attribute
  # is only used by the package installer!**. The log directory will be owned
  # by the same user and group as the home directory. If you need furthor
  # customization, you should override these values in your wrapper cookbook.
  #
  #   node.normal['jenkins']['master']['log_directory'] = '/var/log/jenkins'
  #
  master['log_directory'] = '/var/log/jenkins'

  # Whether to enable web access logging or not.
  # Set to "yes" to enable logging to /var/log/$NAME/access_log
  master['access_log'] = 'no'

  #
  # Set the max open files to a specific value.
  # Due to http://github.com/jenkinsci/jenkins/commit/2fb288474e980d0e7ff9c4a3b768874835a3e92e
  # reporting that Ubuntu's PAM configuration doesn't include pam_limits.so, and as a result the # of file
  # descriptors are forced to 1024 regardless of /etc/security/limits.conf
  #
  master['maxopenfiles'] = 8192

  #
  # The limits for the Java process running the master server.
  # Example to configure the maximum number of open file descriptors:
  #
  #   node.set['jenkins']['master']['ulimits'] = { 'n' => 8192 }
  #
  master['ulimits'] = nil

  #
  # Sleep time in seconds to allow the update center data to quiesce in Jenkins.
  # This is so that we don't run into issues with plugin installations which can
  # happen depending on system load.
  master['update_center_sleep'] = 5

  #
  # Repository name, URL and key. Default is stable.
  #
  master['repository_name'], master['repository'], master['repository_key'] =
    case [node['platform_family'], node['jenkins']['master']['channel']]
    when %w(debian stable)
      ['jenkins-ci-stable', 'https://pkg.jenkins.io/debian-stable', 'https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key']
    when %w(rhel stable), %w(amazon stable)
      ['jenkins-ci-stable', 'https://pkg.jenkins.io/redhat-stable', 'https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key']
    when %w(debian current)
      ['jenkins-ci-current', 'https://pkg.jenkins.io/debian', 'https://pkg.jenkins.io/debian/jenkins.io-2023.key']
    when %w(rhel current), %w(amazon current)
      ['jenkins-ci-current', 'https://pkg.jenkins.io/redhat', 'https://pkg.jenkins.io/redhat/jenkins.io-2023.key']
    end

  #
  # Keyserver to use. Disabled by default
  #
  master['repository_keyserver'] = nil

  #
  # Set extra variables
  #
  master['extra_variables'] = {}
end
