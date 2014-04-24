include_recipe 'jenkins::master'

# Load user data from a data bag item. This should be an encrypted data
# bag item in real deployments.
jenkins_user_data = data_bag_item('keys', 'jenkins-ssh')

#########################################################################
# USER WITH PASSWORD AUTH
#########################################################################
user 'jenkins-ssh-password' do
  home     '/home/jenkins-ssh-password'
  supports manage_home: true
  password jenkins_user_data['password_md5']
end

#########################################################################
# USER WITH KEY-BASED AUTH
#########################################################################
require 'openssl'
require 'net/ssh'
key = OpenSSL::PKey::RSA.new(jenkins_user_data['private_key'])
private_key = key.to_pem
public_key  = "#{key.ssh_type} #{[key.to_blob].pack('m0')}"

user 'jenkins-ssh-key' do
  home     '/home/jenkins-ssh-key'
  supports manage_home: true
end

directory ::File.join('/home/jenkins-ssh-key', '.ssh') do
  owner 'jenkins-ssh-key'
  mode  '0700'
end

file ::File.join('/home/jenkins-ssh-key', '.ssh', 'authorized_keys') do
  owner   'jenkins-ssh-key'
  mode    '0600'
  content public_key
end

#########################################################################
# CREDENTIALS
#########################################################################
credentials = jenkins_private_key_credentials 'jenkins-ssh-key' do
  id '38537014-ec66-49b5-aff2-aed1c19e2989'
  private_key private_key
end

jenkins_password_credentials 'jenkins-ssh-password' do
  password jenkins_user_data['password_clear']
end

#########################################################################
# SSH SLAVES
#########################################################################

# Credentials from resource
jenkins_ssh_slave 'ssh-builder' do
  description 'A builder, but over SSH'
  remote_fs   '/tmp/slave-ssh-builder'
  labels      %w(builer linux)
  user        'jenkins-ssh-key'
  # SSH specific attributes
  host        'localhost'
  credentials credentials
end

# Credentials from UUID
jenkins_ssh_slave 'ssh-executor' do
  description 'An executor, but over SSH'
  remote_fs   '/tmp/slave-ssh-executor'
  labels      %w(executor freebsd jail)
  user        'jenkins-ssh-key'
  # SSH specific attributes
  host        'localhost'
  credentials '38537014-ec66-49b5-aff2-aed1c19e2989'
end

# Credentials from username
jenkins_ssh_slave 'ssh-smoke' do
  description 'A smoke tester, but over SSH'
  remote_fs   '/home/jenkins-ssh-password'
  labels      %w(runner fast)
  user        'jenkins-ssh-password'
  # SSH specific attributes
  host        'localhost'
  credentials 'jenkins-ssh-password'
end
