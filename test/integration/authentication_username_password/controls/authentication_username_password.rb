# copyright: 2026, Sous Chefs

title 'Jenkins Authentication Username password'

control 'jenkins_authentication_username_password-1.0' do
  impact 0.7
  title 'Username/password authentication manages secured Jenkins resources'

  describe jenkins_plugin('greenballs') do
    it { should exist }
  end

  describe jenkins_user('random-bob') do
    it { should exist }
  end

  describe jenkins_job('secure-smoke') do
    it { should exist }
    its('command') { should eq 'echo secure username password' }
  end

  describe file('/var/lib/jenkins/chef-script-marker.txt') do
    it { should exist }
    its('content') { should eq 'username-password' }
  end
end
