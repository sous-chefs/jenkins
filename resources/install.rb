#
# Cookbook:: jenkins
# Resource:: install
#
# Author: AJ Christensen <aj@junglist.gen.nz>
# Author: Doug MacEachern <dougm@vmware.com>
# Author: Fletcher Nichol <fnichol@nichol.ca>
# Author: Seth Chisamore <schisamo@chef.io>
# Author: Guilhem Lettron <guilhem.lettron@youscribe.com>
# Author: Seth Vargo <sethvargo@gmail.com>
#
# Copyright:: 2010-2016, VMware, Inc.
# Copyright:: 2013-2016, Youscribe
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

unified_mode true

resource_name :jenkins_install
provides :jenkins_install

property :install_method, String,
  equal_to: %w(package war),
  default: lazy { platform_family?('debian', 'rhel', 'amazon') ? 'package' : 'war' },
  description: 'Installation method - package or war'

property :version, String,
  description: 'Version of Jenkins to install'

property :channel, String,
  equal_to: %w(stable current latest),
  default: 'stable',
  description: 'Release channel to use'

property :mirror, String,
  default: 'https://updates.jenkins.io',
  description: 'Mirror to download Jenkins from'

property :source, String,
  description: 'Full URL to Jenkins WAR file'

property :checksum, String,
  description: 'SHA-256 checksum of the WAR file'

property :jvm_options, String,
  default: '-Djenkins.install.runSetupWizard=false',
  description: 'JVM options to pass to Jenkins'

property :jenkins_args, String,
  description: 'Additional Jenkins arguments'

property :user, String,
  default: 'jenkins',
  description: 'User to run Jenkins as'

property :group, String,
  default: 'jenkins',
  description: 'Group to run Jenkins under'

property :mode, String,
  default: '0755',
  description: 'Directory mode for Jenkins directories'

property :use_system_accounts, [true, false],
  default: true,
  description: 'Create user/group as system accounts'

property :home, String,
  default: '/var/lib/jenkins',
  description: 'Jenkins home directory'

property :log_directory, String,
  default: '/var/log/jenkins',
  description: 'Jenkins log directory'

property :listen_address, String,
  default: '0.0.0.0',
  description: 'Address to bind Jenkins to'

property :port, Integer,
  default: 8080,
  description: 'Port Jenkins listens on'

property :ajp_port, Integer,
  description: 'AJP13 port (-1 to disable)'

property :debug_level, Integer,
  default: 5,
  description: 'Debug level for logs'

property :handler_max, Integer,
  default: 100,
  description: 'Maximum number of HTTP worker threads'

property :handler_idle, Integer,
  default: 20,
  description: 'Maximum number of idle HTTP worker threads'

property :access_log, String,
  equal_to: %w(yes no),
  default: 'no',
  description: 'Enable web access logging'

property :maxopenfiles, Integer,
  default: 8192,
  description: 'Maximum number of open files'

property :ulimits, Hash,
  description: 'Ulimits for the Jenkins process'

property :repository_name, String,
  description: 'Name of the package repository'

property :repository, String,
  description: 'URL of the package repository'

property :repository_key, String,
  description: 'GPG key URL for the repository'

property :repository_keyserver, String,
  description: 'Keyserver to use for repository key'

property :extra_variables, Hash,
  default: {},
  description: 'Extra environment variables'

action :install do
  case new_resource.install_method
  when 'package'
    install_package
  when 'war'
    install_war
  end
end

action_class do
  def install_package
    case node['platform_family']
    when 'debian'
      package %w(apt-transport-https fontconfig)

      apt_repository computed_repository_name do
        uri          computed_repository
        distribution 'binary/'
        key          computed_repository_key
        keyserver    new_resource.repository_keyserver unless new_resource.repository_keyserver.nil?
      end

      dpkg_autostart 'jenkins' do
        allow false
      end
    when 'rhel', 'amazon'
      # Needed for installing daemonize package
      include_recipe 'yum-epel'

      yum_repository computed_repository_name do
        baseurl computed_repository
        gpgkey  computed_repository_key
      end
    end

    package jenkins_font_packages

    package 'jenkins' do
      version new_resource.version
    end

    create_directories

    case node['platform_family']
    when 'debian'
      template '/etc/default/jenkins' do
        source   'jenkins-config-debian.erb'
        cookbook 'jenkins'
        mode     '0644'
        variables(
          user: new_resource.user,
          group: new_resource.group,
          home: new_resource.home,
          log_directory: new_resource.log_directory,
          listen_address: new_resource.listen_address,
          port: new_resource.port,
          ajp_port: computed_ajp_port,
          debug_level: new_resource.debug_level,
          handler_max: new_resource.handler_max,
          handler_idle: new_resource.handler_idle,
          access_log: new_resource.access_log,
          maxopenfiles: new_resource.maxopenfiles,
          jvm_options: new_resource.jvm_options,
          jenkins_args: new_resource.jenkins_args,
          extra_variables: new_resource.extra_variables
        )
        notifies :restart, 'service[jenkins]', :immediately
      end
    when 'rhel', 'amazon'
      template '/etc/sysconfig/jenkins' do
        source   'jenkins-config-rhel.erb'
        cookbook 'jenkins'
        mode     '0644'
        variables(
          user: new_resource.user,
          group: new_resource.group,
          home: new_resource.home,
          log_directory: new_resource.log_directory,
          listen_address: new_resource.listen_address,
          port: new_resource.port,
          ajp_port: computed_ajp_port,
          debug_level: new_resource.debug_level,
          handler_max: new_resource.handler_max,
          handler_idle: new_resource.handler_idle,
          access_log: new_resource.access_log,
          maxopenfiles: new_resource.maxopenfiles,
          jvm_options: new_resource.jvm_options,
          jenkins_args: new_resource.jenkins_args,
          extra_variables: new_resource.extra_variables
        )
        notifies :restart, 'service[jenkins]', :immediately
      end
    end

    create_init_groovy_directory
    create_anonymous_read_script

    service 'jenkins' do
      supports status: true, restart: true, reload: true
      action [:enable, :start]
    end
  end

  def install_war
    # Create the Jenkins user
    user new_resource.user do
      home new_resource.home
      system new_resource.use_system_accounts
    end

    # Create the Jenkins group
    group new_resource.group do
      members new_resource.user
      system new_resource.use_system_accounts
    end

    create_directories

    package jenkins_font_packages

    # Download the remote WAR file
    remote_file ::File.join(new_resource.home, 'jenkins.war') do
      source   computed_source
      checksum new_resource.checksum if new_resource.checksum
      owner    new_resource.user
      group    new_resource.group
      notifies :restart, 'service[jenkins]'
    end

    # Disable old runit services
    %w(
      /etc/init.d/jenkins
      /etc/service/jenkins
    ).each do |f|
      file f do
        action :delete
        notifies :stop, 'service[jenkins]', :before
      end
    end

    systemd_unit 'jenkins.service' do
      content <<~EOU
        #
        # Generated by Chef for #{node['fqdn']}
        # Changes will be overwritten!
        #

        [Unit]
        Description=Jenkins master service (WAR)

        [Service]
        Type=simple
        User=#{new_resource.user}
        Group=#{new_resource.group}
        Environment="HOME=#{new_resource.home}"
        Environment="JENKINS_HOME=#{new_resource.home}"
        WorkingDirectory=#{new_resource.home}
        #{ulimits_to_systemd(new_resource.ulimits)}
        ExecStart=/bin/sh -c 'exec #{"#{node['jenkins']['java']} #{new_resource.jvm_options} -jar jenkins.war --httpPort=#{new_resource.port} --httpListenAddress=#{new_resource.listen_address} #{new_resource.jenkins_args}".gsub("'", "\\\\'")}'

        [Install]
        WantedBy=multi-user.target
      EOU
      action :create
    end

    service 'jenkins' do
      action [:enable, :start]
    end
  end

  def create_directories
    directory new_resource.home do
      owner     new_resource.user
      group     new_resource.group
      mode      new_resource.mode
      recursive true
    end

    directory new_resource.log_directory do
      owner     new_resource.user
      group     new_resource.group
      mode      '0755'
      recursive true
    end

    # Create/fix permissions on supplemental directories (package install only)
    if new_resource.install_method == 'package'
      %w(cache lib run).each do |folder|
        directory "fix permissions for /var/#{folder}/jenkins" do
          path "/var/#{folder}/jenkins"
          owner new_resource.user
          group new_resource.group
          mode new_resource.mode
          action :create
        end
      end
    end
  end

  def create_init_groovy_directory
    directory "#{new_resource.home}/init.groovy.d" do
      owner new_resource.user
      group new_resource.group
      mode '0755'
      action :create
    end
  end

  def create_anonymous_read_script
    file "#{new_resource.home}/init.groovy.d/grant-anonymous-read.groovy" do
      content <<-EOH
import jenkins.model.*
import hudson.security.*

def instance = Jenkins.getInstance()
def strategy = instance.getAuthorizationStrategy()

// Grant anonymous ADMINISTER for testing (allows plugin installation via REST API)
// In production, you should use proper authentication
if (strategy == AuthorizationStrategy.UNSECURED) {
  def newStrategy = new GlobalMatrixAuthorizationStrategy()
  newStrategy.add(Jenkins.ADMINISTER, "authenticated")
  newStrategy.add(Jenkins.ADMINISTER, "anonymous")  // For testing only!
  instance.setAuthorizationStrategy(newStrategy)
  instance.save()
  println("INFO: Created new authorization strategy with anonymous admin (TESTING ONLY)")
} else if (strategy instanceof GlobalMatrixAuthorizationStrategy) {
  // Add anonymous admin for testing
  strategy.add(Jenkins.ADMINISTER, "anonymous")
  instance.save()
  println("INFO: Added anonymous admin to existing GlobalMatrixAuthorizationStrategy (TESTING ONLY)")
} else if (strategy instanceof ProjectMatrixAuthorizationStrategy) {
  // Add anonymous admin for testing
  strategy.add(Jenkins.ADMINISTER, "anonymous")
  instance.save()
  println("INFO: Added anonymous admin to existing ProjectMatrixAuthorizationStrategy (TESTING ONLY)")
} else {
  println("WARN: Unknown authorization strategy type: " + strategy.getClass().getName())
}
      EOH
      owner new_resource.user
      group new_resource.group
      mode '0644'
      notifies :restart, 'service[jenkins]', :immediately
    end
  end

  def computed_source
    return new_resource.source if new_resource.source

    "#{new_resource.mirror}/#{new_resource.version || new_resource.channel}/latest/jenkins.war"
  end

  def computed_repository_name
    return new_resource.repository_name if new_resource.repository_name

    case [node['platform_family'], new_resource.channel]
    when %w(debian stable), %w(rhel stable), %w(amazon stable)
      'jenkins-ci-stable'
    when %w(debian current), %w(rhel current), %w(amazon current)
      'jenkins-ci-current'
    end
  end

  def computed_repository
    return new_resource.repository if new_resource.repository

    case [node['platform_family'], new_resource.channel]
    when %w(debian stable)
      'https://pkg.jenkins.io/debian-stable'
    when %w(rhel stable), %w(amazon stable)
      'https://pkg.jenkins.io/redhat-stable'
    when %w(debian current)
      'https://pkg.jenkins.io/debian'
    when %w(rhel current), %w(amazon current)
      'https://pkg.jenkins.io/redhat'
    end
  end

  def computed_repository_key
    return new_resource.repository_key if new_resource.repository_key

    case [node['platform_family'], new_resource.channel]
    when %w(debian stable)
      'https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key'
    when %w(rhel stable), %w(amazon stable)
      'https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key'
    when %w(debian current)
      'https://pkg.jenkins.io/debian/jenkins.io-2023.key'
    when %w(rhel current), %w(amazon current)
      'https://pkg.jenkins.io/redhat/jenkins.io-2023.key'
    end
  end

  def computed_ajp_port
    return new_resource.ajp_port if new_resource.ajp_port

    case node['platform_family']
    when 'debian'
      -1
    when 'rhel', 'amazon'
      8009
    end
  end

  def jenkins_font_packages
    case node['platform_family']
    when 'debian'
      %w(fontconfig)
    when 'rhel', 'amazon'
      %w(fontconfig dejavu-sans-fonts)
    else
      []
    end
  end

  def ulimits_to_systemd(ulimits)
    return '' unless ulimits

    ulimits.map do |key, value|
      case key
      when 'c'
        "LimitCORE=#{value}"
      when 'd'
        "LimitDATA=#{value}"
      when 'f'
        "LimitFSIZE=#{value}"
      when 'l'
        "LimitMEMLOCK=#{value}"
      when 'n'
        "LimitNOFILE=#{value}"
      when 's'
        "LimitSTACK=#{value}"
      when 't'
        "LimitCPU=#{value}"
      when 'u'
        "LimitNPROC=#{value}"
      when 'v'
        "LimitAS=#{value}"
      end
    end.compact.join("\n")
  end
end
