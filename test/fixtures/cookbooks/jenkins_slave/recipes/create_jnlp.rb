#
# JNLP
# ------------------------------

# Test basic JNLP slave creation
jenkins_jnlp_slave 'jnlp-builder' do
  description  'A generic slave builder'
  remote_fs    '/tmp/jenkins/slaves/builder'
  service_name 'jenkins-slave-builder'
  usage_mode   'exclusive'
  labels       %w(builder linux)
  user         'jenkins-builder'
  group        'jenkins-builder'

  action :create
end

# Test more exotic JNLP slave creation
jenkins_jnlp_slave 'jnlp-smoke' do
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
  service_groups %w(jenkins-smoke)

  action :create
end

# Test with environment variables
jenkins_jnlp_slave 'jnlp-executor' do
  description  'Run test suites'
  remote_fs    '/tmp/jenkins/slaves/executor'
  service_name 'jenkins-slave-executor'
  usage_mode   'exclusive'
  labels       %w(executor freebsd jail)
  user         'jenkins-executor'
  group        'jenkins-executor'
  environment(
    'FOO' => 'bar',
    'BAZ' => 'qux'
  )

  action :create
end
