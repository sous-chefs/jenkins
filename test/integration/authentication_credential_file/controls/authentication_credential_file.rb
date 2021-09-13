# copyright: 2018, The Authors

title 'Jenkins Authentication Credential File'

control 'jenkins_authentication_credential_file-1.0' do
  impact 0.7
  title 'Users and plugins are installed after setting PAM security'

  describe jenkins_plugin('greenballs') do
    it { should exist }
  end

  describe jenkins_user('random-bob') do
    it { should exist }
  end
end
