jenkins_ssh_slave 'ssh-to-delete' do
  action :create
end

jenkins_ssh_slave 'ssh-to-delete' do
  action :delete
end

jenkins_ssh_slave 'ssh-missing' do
  action :delete
end
