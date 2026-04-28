# copyright: 2026, Sous Chefs

title 'Jenkins Authentication Credential File'

control 'jenkins_authentication_credential_file-1.0' do
  impact 0.7
  title 'Credential-file authentication manages secured Jenkins resources'

  describe file('/var/lib/jenkins/.cli-credentials') do
    it { should exist }
    its('mode') { should cmp '0600' }
  end

  describe jenkins_plugin('greenballs') do
    it { should exist }
  end

  describe jenkins_user('random-bob') do
    it { should exist }
  end

  describe jenkins_job('secure-smoke') do
    it { should exist }
    its('command') { should eq 'echo secure credential file' }
  end

  describe file('/var/lib/jenkins/chef-script-marker.txt') do
    it { should exist }
    its('content') { should eq 'credential-file' }
  end
end
