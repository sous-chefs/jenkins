jenkins_ssh_slave 'ssh-to-connect' do
  remote_fs   '/tmp/ssh-to-connect'

  user        'jenkins-ssh-password'
  # SSH specific attributes
  host        'localhost'
  credentials 'jenkins-ssh-password'
  launch_timeout   node['jenkins_slave']['launch_timeout']
  ssh_retries      5
  ssh_wait_retries 60
end

jenkins_slave 'ssh-to-connect' do
  action :disconnect
end

jenkins_slave 'ssh-to-connect' do
  action :connect
end
