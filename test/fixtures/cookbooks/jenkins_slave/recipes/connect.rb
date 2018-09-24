jenkins_ssh_slave 'ssh-to-connect' do
  description 'A smoke tester, but over SSH'
  remote_fs   '/tmp/ssh-to-connect'
  labels      %w(runner fast)
  user        'jenkins-ssh-password'
  # SSH specific attributes
  host        'localhost'
  credentials 'jenkins-ssh-password'
  launch_timeout   30
  ssh_retries      5
  ssh_wait_retries 60
end

jenkins_slave 'ssh-to-connect' do
  action :disconnect
end

jenkins_slave 'ssh-to-connect' do
  action :connect
end
