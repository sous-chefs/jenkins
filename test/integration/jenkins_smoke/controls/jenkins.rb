# copyright: 2018, The Authors

title 'Jenkins'

control 'jenkins-1.0' do
  impact 0.7
  title 'Jenkins is running'

  describe runit_service('jenkins') do
    it { should be_installed }
    it { should be_enabled }
    it { should be_running }
  end
end

control 'jenkins-2.0' do
  impact 0.7
  title 'Jenkins is listening'

  describe port('8080') do
    it { should be_listening }
  end
end
