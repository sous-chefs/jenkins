#
# This recipe is a meta-collection of some common paths in the Jenkins cookbook.
# It should be run instead of the individual resource tests during trivial
# patches.
#
# This recipe will:
#   - Execute some basic commands
#   - Manage credentials (create, delete)
#   - Manage jobs (create, remove disable)
#   - Manage plugins (install, uninstall, disable, enable)
#   - Manage JNLP slaves (create, delete, connect, disconnect, online, offline)
#   - Manage SSH slaves (create, delete, connect, disconnect, online, offline)
#

include_recipe 'jenkins::master'

#
# Commands
# ------------------------------

jenkins_command 'clear-queue'
jenkins_command 'help'
jenkins_command 'version'

#
# Credentials
# ------------------------------

# Create some basic credentials
%w[sethvargo schisamo].each do |name|
  jenkins_password_credentials name do
    password 'sUp3rS#curE'
  end
end

# Create a private-key user
jenkins_private_key_credentials 'vagrant' do
  description 'Vagrant'
  private_key <<-EOH.gsub(/^ {4}/, '')
    -----BEGIN RSA PRIVATE KEY-----
    MIIEogIBAAKCAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzI
    w+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoP
    kcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2
    hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NO
    Td0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcW
    yLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQIBIwKCAQEA4iqWPJXtzZA68mKd
    ELs4jJsdyky+ewdZeNds5tjcnHU5zUYE25K+ffJED9qUWICcLZDc81TGWjHyAqD1
    Bw7XpgUwFgeUJwUlzQurAv+/ySnxiwuaGJfhFM1CaQHzfXphgVml+fZUvnJUTvzf
    TK2Lg6EdbUE9TarUlBf/xPfuEhMSlIE5keb/Zz3/LUlRg8yDqz5w+QWVJ4utnKnK
    iqwZN0mwpwU7YSyJhlT4YV1F3n4YjLswM5wJs2oqm0jssQu/BT0tyEXNDYBLEF4A
    sClaWuSJ2kjq7KhrrYXzagqhnSei9ODYFShJu8UWVec3Ihb5ZXlzO6vdNQ1J9Xsf
    4m+2ywKBgQD6qFxx/Rv9CNN96l/4rb14HKirC2o/orApiHmHDsURs5rUKDx0f9iP
    cXN7S1uePXuJRK/5hsubaOCx3Owd2u9gD6Oq0CsMkE4CUSiJcYrMANtx54cGH7Rk
    EjFZxK8xAv1ldELEyxrFqkbE4BKd8QOt414qjvTGyAK+OLD3M2QdCQKBgQDtx8pN
    CAxR7yhHbIWT1AH66+XWN8bXq7l3RO/ukeaci98JfkbkxURZhtxV/HHuvUhnPLdX
    3TwygPBYZFNo4pzVEhzWoTtnEtrFueKxyc3+LjZpuo+mBlQ6ORtfgkr9gBVphXZG
    YEzkCD3lVdl8L4cw9BVpKrJCs1c5taGjDgdInQKBgHm/fVvv96bJxc9x1tffXAcj
    3OVdUN0UgXNCSaf/3A/phbeBQe9xS+3mpc4r6qvx+iy69mNBeNZ0xOitIjpjBo2+
    dBEjSBwLk5q5tJqHmy/jKMJL4n9ROlx93XS+njxgibTvU6Fp9w+NOFD/HvxB3Tcz
    6+jJF85D5BNAG3DBMKBjAoGBAOAxZvgsKN+JuENXsST7F89Tck2iTcQIT8g5rwWC
    P9Vt74yboe2kDT531w8+egz7nAmRBKNM751U/95P9t88EDacDI/Z2OwnuFQHCPDF
    llYOUI+SpLJ6/vURRbHSnnn8a/XG+nzedGH5JGqEJNQsz+xT2axM0/W/CRknmGaJ
    kda/AoGANWrLCz708y7VYgAtW2Uf1DPOIYMdvo6fxIB5i9ZfISgcJ/bbCUkFrhoH
    +vq/5CIWxCPp0f85R4qxxQ5ihxJ0YDQT9Jpx4TMss4PSavPaBH3RXow5Ohe+bYoQ
    NE5OgEXk2wVfZczCZpigBKbKZHNYcelXtTt/nP3rsCuGcM4h53s=
    -----END RSA PRIVATE KEY-----
  EOH
end

# Remove a credential
jenkins_credentials 'sethvargo' do
  action :delete
end

# Remove a non-existent credential
jenkins_credentials 'yzl' do
  action :delete
end

#
# Jobs
# ------------------------------

# Create multiple jobs
%w[builder executor runner].each do |name|
  config = File.join(Chef::Config[:file_cache_path], "#{name}-job-config.xml")

  template config do
    source 'config.xml.erb'
    variables(name: name)
  end

  jenkins_job name do
    config config
  end
end

# Remove a job
jenkins_job 'builder' do
  action :delete
end

# Remove a non-existent job
jenkins_job 'windows' do
  action :delete
end

# Disable a job
jenkins_job 'executor' do
  action :disable
end

# Enable a job
jenkins_job 'executor' do
  action :enable
end

#
# Plugins
# ------------------------------

# Install some plugins
%w[greenballs disk-usage copy-to-slave].each do |name|
  jenkins_plugin name
end

# Restart jenkins to install the plugins
jenkins_command 'restart'

# Uninstall a plugin
jenkins_plugin 'greenballs' do
  action :uninstall
end

# Uninstall a non-existent plugin
jenkins_plugin 'fancypants' do
  action :uninstall
end

# Restart jenkins to reload plugins
jenkins_command 'restart'

# Disable a plugin
jenkins_plugin 'disk-usage' do
  action :disable
end

# Enable a plugin
jenkins_plugin 'disk-usage' do
  action :enable
end

#
# Slaves
# ------------------------------

# Create some JNLP slaves
%w[builder executor smoke].each do |name|
  jenkins_jnlp_slave "#{name}" do
    description  "A generic slave #{name}"
    remote_fs    "/tmp/jenkins/slaves/#{name}"
    service_name "jenkins-slave-#{name}"
    labels       %W[#{name} linux]
    user         "jenkins-#{name}"
    group        "jenkins-#{name}"
  end
end

# Create some SSH slaves
key = File.read(File.expand_path('../../../../../data/data/test_id_rsa', __FILE__))
credentials = jenkins_private_key_credentials('smoke-key') { private_key key }

%w[ssh-builder ssh-executor ssh-smoke].each do |name|
  jenkins_ssh_slave "#{name}" do
    description "#{name}, but over SSH"
    remote_fs   "/tmp/jenkins/slaves/#{name}"
    labels      %W[#{name} builer linux]
    user        "jenkins-#{name}"
    group       "jenkins-#{name}"

    # SSH specific attributes
    host        'localhost'
    credentials credentials
  end
end

# Delete JNLP slave
jenkins_jnlp_slave 'builder' do
  action :delete
end

# Delete SSH slave
jenkins_ssh_slave 'ssh-builder' do
  action :delete
end

# Disconnect JNLP slave
jenkins_jnlp_slave 'executor' do
  action :disconnect
end

# Disconnect SSH slave
jenkins_ssh_slave 'ssh-executor' do
  action :disconnect
end

# Restart
jenkins_command 'restart'

# Connection JNLP slave
jenkins_jnlp_slave 'executor' do
  action :connect
end

# Connection SSH slave
jenkins_ssh_slave 'ssh-executor' do
  action :connect
end

# Restart
jenkins_command 'restart'

# Offline JNLP Slave
jenkins_jnlp_slave 'executor' do
  action :offline
end

# Offline SSH slave
jenkins_ssh_slave 'ssh-executor' do
  action :offline
end

# Restart
jenkins_command 'restart'

# Online JNLP Slave
jenkins_jnlp_slave 'executor' do
  action :online
end

# Online SSH slave
jenkins_ssh_slave 'ssh-executor' do
  action :online
end

#
# Users
# ------------------------------

# Create some users
%w[sethvargo schisamo].each do |username|
  jenkins_user username
end

# Create a user with specific attributes
jenkins_user 'yzl' do
  full_name   'Yvonne Lam'
  email       'yzl@example.com'
  public_keys ['ssh-rsa AAAAB3NzaC1y...']
end

# Delete a user
jenkins_user 'sethvargo' do
  action :delete
end
