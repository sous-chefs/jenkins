cookbook_file '/var/jenkins_test_job.xml' do
  source 'test_job.xml'
end

jenkins_job 'test' do
  config '/var/jenkins_test_job.xml'
  action :create
end

jenkins_job 'test' do
  action :build
end

ruby_block 'sleep 10' do
  block do
    sleep 10
  end
end

jenkins_job 'test' do
  action :disable
end

jenkins_job 'test' do
  action :enable
end

jenkins_job 'test' do
  action :delete
end
