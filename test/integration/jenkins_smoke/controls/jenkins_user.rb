# copyright: 2018, The Authors

title 'Jenkins Users'

control 'jenkins_user-1.0' do
  impact 0.7
  title 'jenkins Users are created'

  describe jenkins_user('sethvargo') do
    it { should exist }
  end

  describe jenkins_user('schisamo') do
    it { should exist }
    its('full_name') { should eq('Seth Chisamore') }
    its('email') { should eq('schisamo@chef.io') }
    its('public_key') { should include('ssh-rsa AAAAAAA') }
  end

  describe jenkins_user('valyukov') do
    it { should exist }
    its('password_hash') { should start_with '#jbcrypt:' }
    its('public_key') { should eq(['ssh-rsa BBBBBBB', 'ssh-rsa CCCCCCC']) }
  end
end

control 'jenkins_user-2.0' do
  impact 0.7
  title 'jenkins Users are deleted'

  describe jenkins_user('delete-user') do
    it { should_not exist }
  end

  describe jenkins_user('missing-user') do
    it { should_not exist }
  end
end
