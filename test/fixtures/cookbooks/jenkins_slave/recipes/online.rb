jenkins_ssh_slave 'ssh-to-online' do
  remote_fs   '/tmp/ssh-to-online'
  user        'jenkins-ssh-password'
  # SSH specific attributes
  host        'localhost'
  credentials 'jenkins-ssh-password'
  launch_timeout   node['jenkins_slave']['launch_timeout']
  ssh_retries      5
  ssh_wait_retries 60
end

jenkins_slave 'ssh-to-online' do
  action :offline
end

jenkins_slave 'ssh-to-online' do
  action :online
end

jenkins_slave 'online ssh slave again' do
  slave_name 'ssh-to-online'
  action :online
end
