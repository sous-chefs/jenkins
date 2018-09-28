
jenkins_ssh_slave 'ssh-to-offline' do
  description 'A smoke tester, but over SSH'
  remote_fs   '/tmp/ssh-to-offline'
  labels      %w(runner fast)
  user        'jenkins-ssh-password'
  # SSH specific attributes
  host        'localhost'
  credentials 'jenkins-ssh-password'
  launch_timeout   30
  ssh_retries      5
  ssh_wait_retries 60
end

jenkins_slave 'ssh-to-offline' do
  offline_reason 'Autobots ran out of energy'

  action :offline
end

jenkins_slave 'offline ssh slave again' do
  slave_name 'ssh-to-offline'
  offline_reason 'Autobots ran out of energy'

  action :offline
end
