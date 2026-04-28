# copyright: 2026, Sous Chefs

title 'Jenkins Secure Controller'

control 'jenkins_authentication-1.0' do
  impact 0.7
  title 'Jenkins runs with security enabled'

  describe service('jenkins') do
    it { should be_enabled }
    it { should be_running }
  end

  describe port(8080) do
    it { should be_listening }
  end

  describe file('/var/lib/jenkins/config.xml') do
    it { should exist }
    its('content') { should match('<useSecurity>true</useSecurity>') }
    its('content') { should match('FullControlOnceLoggedInAuthorizationStrategy') }
    its('content') { should match('HudsonPrivateSecurityRealm') }
  end

  describe jenkins_user('chef') do
    it { should exist }
    its('full_name') { should eq 'Chef Client' }
  end
end
