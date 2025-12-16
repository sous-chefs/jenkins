# copyright: 2024, Sous Chefs

title 'Jenkins Authentication Test'

control 'jenkins_authentication-1.0' do
  impact 0.7
  title 'Users and plugins are installed'

  describe jenkins_user('chef') do
    it { should exist }
    its('full_name') { should eq 'Chef Client' }
  end

  describe jenkins_plugin('greenballs') do
    it { should exist }
  end

  describe jenkins_user('random-bob') do
    it { should exist }
  end
end
