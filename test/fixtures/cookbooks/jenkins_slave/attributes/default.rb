case node['platform_family']
when 'debian'
  default['sshd_service'] = 'ssh'
when 'rhel', 'amazon'
  default['sshd_service'] = 'sshd'
end
