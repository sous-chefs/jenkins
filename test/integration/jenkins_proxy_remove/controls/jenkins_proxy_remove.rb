# copyright: 2018, The Authors

title 'Jenkins Proxy'

control 'jenkins_proxy_remove-1.0' do
  impact 0.7
  title 'Jenkins Proxy is deleted'

  describe jenkins_proxy('1.2.3.4:5678') do
    it { should_not exist }
  end

  describe jenkins_proxy('5.6.7.8:9012') do
    it { should_not exist }
  end
end
