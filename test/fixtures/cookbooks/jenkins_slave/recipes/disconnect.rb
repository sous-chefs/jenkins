jenkins_ssh_slave 'ssh-to-disconnect' do
  remote_fs   '/tmp/ssh-to-disconnect'
  user        'jenkins-ssh-password'
  # SSH specific attributes
  host        'localhost'
  credentials 'jenkins-ssh-password'
  launch_timeout   node['jenkins_slave']['launch_timeout']
  ssh_retries      5
  ssh_wait_retries 60
end

jenkins_slave 'ssh-to-disconnect' do
  action :disconnect
end

jenkins_slave 'disconnect ssh slave again' do
  slave_name 'ssh-to-disconnect'
  action :disconnect
end
