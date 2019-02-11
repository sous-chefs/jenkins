jenkins_jnlp_slave 'jnlp-to-delete' do
  remote_fs    '/tmp/jenkins/slaves/jnlp-to-delete'
  service_name 'jnlp-to-delete'
  user         'jnlp-to-delete'
  group        'jnlp-to-delete'

  action :create
end

jenkins_jnlp_slave 'jnlp-to-delete' do
  action :delete
end

jenkins_jnlp_slave 'jnlp-missing' do
  action :delete
end
