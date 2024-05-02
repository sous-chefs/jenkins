unified_mode true
use 'partials/slave'

property :group, String,
          default: 'jenkins',
          regex: Config[:group_valid_regex]

property :service_name, String,
          default: 'jenkins-slave'

property :service_groups, Array,
          default: lazy { [group] }

deprecated_property_alias 'runit_groups', 'service_groups',
  '`runit_groups` was renamed to `service_groups` with the move to systemd services'

def load_current_resource
  @current_resource ||= Resource::JenkinsJnlpSlave.new(new_resource.name)
  super
end

action :create do
  do_create

  declare_resource(:directory, ::File.expand_path(new_resource.remote_fs, '..')) do
    recursive(true)
    action :create
  end

  unless platform?('windows')
    declare_resource(:group, new_resource.group) do
      system(node['jenkins']['master']['use_system_accounts'])
    end

    declare_resource(:user, new_resource.user) do
      gid(new_resource.group)
      comment('Jenkins slave user - Created by Chef')
      home(new_resource.remote_fs)
      system(node['jenkins']['master']['use_system_accounts'])
      action :create
    end
  end

  declare_resource(:directory, new_resource.remote_fs) do
    owner(new_resource.user)
    group(new_resource.group)
    recursive(true)
    action :create
  end

  declare_resource(:remote_file, slave_jar).tap do |r|
    # We need to use .tap() to access methods in the provider's scope.
    r.source slave_jar_url
    r.backup(false)
    r.mode('0755')
    r.atomic_update(false)
    r.notifies :restart, "systemd_unit[#{new_resource.service_name}.service]" unless platform?('windows')
  end

  # The Windows's specific child class manages it's own service
  return if platform?('windows')

  # disable runit services before starting new service
  # TODO: remove in future version

  %W(
    /etc/init.d/#{new_resource.service_name}
    /etc/service/#{new_resource.service_name}
  ).each do |f|
    file f do
      action :delete
      notifies :stop, "service[#{new_resource.service_name}]", :before
    end
  end

  exec_string = "#{java} #{new_resource.jvm_options}"
  exec_string << " -jar #{slave_jar}" if slave_jar
  exec_string << " -secret #{jnlp_secret}" if jnlp_secret
  exec_string << " -jnlpUrl #{jnlp_url}"

  systemd_unit "#{new_resource.service_name}.service" do
    content <<~EOU
      #
      # Generated by Chef for #{node['fqdn']}
      # Changes will be overwritten!
      #

      [Unit]
      Description=Jenkins JNLP Slave (#{new_resource.service_name})
      After=network.target

      [Service]
      Type=simple
      User=#{new_resource.user}
      Group=#{new_resource.group}
      SupplementaryGroups=#{(new_resource.service_groups - [new_resource.group]).join(' ')}
      Environment="HOME=#{new_resource.remote_fs}"
      Environment="JENKINS_HOME=#{new_resource.remote_fs}"
      WorkingDirectory=#{new_resource.remote_fs}
      ExecStart=#{exec_string}

      [Install]
      WantedBy=multi-user.target
    EOU
    action :create
  end

  service new_resource.service_name do
    action [:enable, :start]
  end
end

action :delete do
  # Stop and remove the service
  service "#{new_resource.service_name}" do
    action [:disable, :stop]
  end

  do_delete
end

action_class do
  #
  # @see Chef::Resource::JenkinsSlave#launcher_groovy
  # @see http://javadoc.jenkins-ci.org/hudson/slaves/JNLPLauncher.html
  #
  def launcher_groovy
    'launcher = new hudson.slaves.JNLPLauncher()'
  end

  #
  # The path (url) of the slave's unique JNLP file on the Jenkins
  # master.
  #
  # @return [String]
  #
  def jnlp_url
    @jnlp_url ||= uri_join(endpoint, 'computer', new_resource.slave_name, 'slave-agent.jnlp')
  end

  #
  # Generates the slaves unique JNLP secret using the Groovy API.
  #
  # @return [String]
  #
  def jnlp_secret
    return @jnlp_secret if @jnlp_secret
    json = executor.groovy! <<~EOH
      output = [
        secret:jenkins.slaves.JnlpSlaveAgentProtocol.SLAVE_SECRET.mac('#{new_resource.slave_name}')
      ]

      builder = new groovy.json.JsonBuilder(output)
      println(builder)
    EOH
    output = JSON.parse(json, symbolize_names: true)
    @jnlp_secret = output[:secret]
  end

  #
  # The url of the +slave.jar+ on the Jenkins master.
  #
  # @return [String]
  #
  def slave_jar_url
    @slave_jar_url ||= uri_join(endpoint, 'jnlpJars', 'slave.jar')
  end

  #
  # The path to the +slave.jar+ on disk (which may or may not exist).
  #
  # @return [String]
  #
  def slave_jar
    ::File.join(new_resource.remote_fs, 'slave.jar')
  end
end
