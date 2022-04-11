# copyright: 2018, The Authors

title 'Jenkins Credentials'

control 'jenkins_credentials-1.0' do
  impact 0.7
  title 'Jenkins Users are created'

  describe jenkins_user_credentials('schisamo') do
    it { should exist }
    its('id') { should eq 'schisamo' }
    its('description') { should eq 'passwords are for suckers' }
    it { should have_password } # 'superseekret'
  end

  describe jenkins_user_credentials('schisamo2') do
    it { should exist }
    its('id') { should eq '63e11302-d446-4ba0-8aa4-f5821f74d36f' }
    it { should have_password } # 'superseekret'
  end

  describe jenkins_user_credentials('schisamo3') do
    it { should exist }
    its('id') { should eq 'schisamo3' }
    it { should have_password } # 'superseekret'
  end

  describe jenkins_user_credentials('dollarbills') do
    it { should exist }
    it { should have_password } # '$uper$ecret'
  end
end

control 'jenkins_credentials-2.0' do
  impact 0.7
  title 'Jenkins Private Key Credentials are created'

  describe jenkins_user_credentials('jenkins') do
    it { should exist }
    its('description') { should eq 'this is more like it' }
    it { should have_private_key }
  end

  describe jenkins_user_credentials('jenkins2') do
    it { should exist }
    it { should have_private_key }
    it { should have_passphrase } # 'secret'
  end

  describe jenkins_user_credentials('jenkins3') do
    it { should exist }
    its('description') { should eq 'I specified an ID' }
    its('id') { should eq '766952b8-e1ea-4ee1-b769-e159681cb893' }
    it { should have_private_key }
  end

  describe jenkins_user_credentials('ecdsa_nopasswd') do
    it { should exist }
    it { should have_private_key }
  end

  describe jenkins_user_credentials('ecdsa_passwd') do
    it { should exist }
    it { should have_private_key }
    it { should have_passphrase } # 'secret'
  end
end

control 'jenkins_credentials-3.0' do
  impact 0.7
  title 'Jenkins Secret Text Credentials are created'

  describe jenkins_secret_text_credentials('dollarbills_secret') do
    it { should exist }
    # its('secret') { should eq '$uper$ecret' }
  end
end

control 'jenkins_credentials-4.0' do
  impact 0.7
  title 'Jenkins Users Credentials are deleted'

  1.upto(3) do |i|
    describe jenkins_secret_text_credentials("user#{i}_delete") do
      it { should_not exist }
    end
  end
end

control 'jenkins_credentials-5.0' do
  impact 0.7
  title 'Jenkins Private Key Credentials are deleted'

  1.upto(3) do |i|
    describe jenkins_secret_text_credentials("private_key_credentials_delete#{i}") do
      it { should_not exist }
    end
  end

  describe jenkins_secret_text_credentials('secret_text_credentials_to_delete') do
    it { should_not exist }
  end
end

control 'jenkins_credentials-6.0' do
  impact 0.7
  title 'Jenkins Secret Text Credentials are deleted'

  describe jenkins_secret_text_credentials('file_to_delete') do
    it { should_not exist }
  end
end
