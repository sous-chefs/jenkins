include_recipe 'jenkins::server'

#
# JNLP
# ------------------------------

# Test basic JNLP slave creation
jenkins_jnlp_slave 'builder' do
  description  'A generic slave builder'
  remote_fs    '/tmp/jenkins/slaves/builder'
  service_name 'jenkins-slave-builder'
  labels       %w[builder linux]
  user         'jenkins-builder'
  group        'jenkins-builder'
end

# Test more exotic JNLP slave creation
jenkins_jnlp_slave 'smoke' do
  description     'Run high-level integration tests'
  remote_fs       '/tmp/jenkins/slaves/smoke'
  service_name    'jenkins-slave-smoke'
  executors       5
  usage_mode      'exclusive'
  availability    'demand'
  in_demand_delay 1
  idle_delay      3
  labels          %w[runner fast]
  user           'jenkins-smoke'
  group          'jenkins-smoke'
end

# Test with environment variables
jenkins_jnlp_slave 'executor' do
  description  'Run test suites'
  remote_fs    '/tmp/jenkins/slaves/executor'
  service_name 'jenkins-slave-executor'
  labels       %w[executor freebsd jail]
  user         'jenkins-executor'
  group        'jenkins-executor'
  environment(
    'FOO' => 'bar',
    'BAZ' => 'qux',
  )
end

#
# SSH
# ------------------------------

# Ugh...need to find a better way to do this...
key_path = File.expand_path('../../../../../data/data/test_id_rsa', __FILE__)
jenkins_master_pk = File.read(key_path)

# Test SSH slave creation - credentials from resource
credentials = jenkins_private_key_credentials 'jenkins-ssh-builder' do
  private_key jenkins_master_pk
end

jenkins_ssh_slave 'ssh-builder' do
  description 'Builder, but over SSH'
  remote_fs   '/tmp/jenkins/slaves/ssh-builder'
  labels      %w[builer linux]
  user        'jenkins-ssh-builder'
  group       'jenkins-ssh-builder'

  # SSH specific attributes
  host        'localhost'
  credentials credentials
end

# Test SSH slave creation - credentials from ID
jenkins_private_key_credentials 'jenkins-ssh-executor' do
  id '38537014-ec66-49b5-aff2-aed1c19e2989'
  private_key jenkins_master_pk
end

jenkins_ssh_slave 'ssh-executor' do
  description 'An executor, but over SSH'
  remote_fs   '/tmp/jenkins/slaves/ssh-executor'
  labels      %w[executor freebsd jail]
  user        'jenkins-ssh-executor'
  group       'jenkins-ssh-executor'

  # SSH specific attributes
  host        'localhost'
  credentials '38537014-ec66-49b5-aff2-aed1c19e2989'
end

# Test SSH slave creation - credentials from username
jenkins_private_key_credentials 'jenkins-ssh-smoke' do
  private_key jenkins_master_pk
end

jenkins_ssh_slave 'ssh-smoke' do
  description 'ssh-Smoke, but over SSH'
  remote_fs   '/tmp/jenkins/slaves/ssh-smoke'
  labels      %w[runner fast]
  user        'jenkins-ssh-smoke'
  group       'jenkins-ssh-smoke'

  # SSH specific attributes
  host        'localhost'
  credentials 'jenkins-ssh-smoke'
end
