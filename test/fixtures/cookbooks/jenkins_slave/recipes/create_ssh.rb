include_recipe 'jenkins::master'

slave_user = node['jenkins']['master']['user']

directory ::File.join(node['jenkins']['master']['home'], '.ssh') do
  owner slave_user
  mode  '0700'
end

file ::File.join(node['jenkins']['master']['home'], '.ssh', 'authorized_keys') do
  owner   slave_user
  mode    '0600'
  content 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDO66p1CYctGZW/eq8ywBqV4+/AxIinZa4SrZhIf3ShGVihFryHiVPYKVhwh7t01/hU1bc085ZUFFafcX1Ie3Gt8K1Ltfmmtik+EFFRZ3FAy+4Ye8XnFTyr3e2O9m/tg9YG/E/1HeeW8frrW40Ub7CJYpZp8xPqCyj5+vyHytnBT6g/XXgt0vcl8jQGAnytj6UN+DZc3EvPnKyTIjXHlYgvTE3EWJgThe5BUu7b1+rO0aQVI4tlHjVce4iLnN+0E3GQuE9Kkzblq418LtkB6hgTQEKGP2MPa7MX3zdH19P0F+SwBRS60X/40uhgp5X94VZIlJODXL8Z8SFNnYfr0LhF'
end

#########################################################################
# CREDENTIALS
#########################################################################
# Ugh...need to find a better way to do this...
key_path = File.expand_path('../../../../../data/data/test_id_rsa', __FILE__)
jenkins_master_pk = File.read(key_path)

credentials = jenkins_private_key_credentials 'pk-creds' do
  username slave_user
  private_key jenkins_master_pk
end

jenkins_private_key_credentials 'pk-creds-with-uuid' do
  id '38537014-ec66-49b5-aff2-aed1c19e2989'
  username slave_user
  private_key jenkins_master_pk
end

#########################################################################
# SSH SLAVES
#########################################################################

# Credentials from resource
jenkins_ssh_slave 'ssh-builder' do
  description 'A builder, but over SSH'
  remote_fs   '/tmp/slave-ssh-builder'
  labels      %w(builer linux)
  user        slave_user
  # SSH specific attributes
  host        'localhost'
  credentials credentials
end

# Credentials from UUID
jenkins_ssh_slave 'ssh-executor' do
  description 'An executor, but over SSH'
  remote_fs   '/tmp/slave-ssh-executor'
  labels      %w(executor freebsd jail)
  user        slave_user
  # SSH specific attributes
  host        'localhost'
  credentials '38537014-ec66-49b5-aff2-aed1c19e2989'
end

# Credentials from username
jenkins_ssh_slave 'ssh-smoke' do
  description 'A smoke tester, but over SSH'
  remote_fs   '/tmp/slave-ssh-smoke'
  labels      %w(runner fast)
  user        slave_user
  # SSH specific attributes
  host        'localhost'
  credentials 'jenkins'
end
