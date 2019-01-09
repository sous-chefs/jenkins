include_recipe 'jenkins_server_wrapper::default'

return if docker? # the runit_service resource has issues under Docker

#
# JNLP
# ------------------------------

# Test basic JNLP slave creation
jenkins_jnlp_slave 'builder' do
  description  'A generic slave builder'
  remote_fs    '/tmp/jenkins/slaves/builder'
  service_name 'jenkins-slave-builder'
  labels       %w(builder linux)
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
  labels          %w(runner fast)
  user           'jenkins-smoke'
  group          'jenkins-smoke'
end

# Test with environment variables
jenkins_jnlp_slave 'executor' do
  description  'Run test suites'
  remote_fs    '/tmp/jenkins/slaves/executor'
  service_name 'jenkins-slave-executor'
  labels       %w(executor freebsd jail)
  user         'jenkins-executor'
  group        'jenkins-executor'
  environment(
    'FOO' => 'bar',
    'BAZ' => 'qux'
  )
end
