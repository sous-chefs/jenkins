case node['platform_family']
when 'debian'
  default['sshd_service'] = 'ssh'
when 'rhel', 'amazon'
  default['sshd_service'] = 'sshd'
end

# launch timeout is 2 minutes so that there's plenty of time for
# the slave to connect to the master

default['jenkins_slave']['launch_timeout'] = 120
