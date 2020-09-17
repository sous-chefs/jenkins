# copyright: 2018, The Authors

title 'Jenkins Proxy'

control 'jenkins_proxy_config-1.0' do
  impact 0.7
  title 'Jenkins Proxy is configured'

  describe jenkins_proxy('1.2.3.4:5678') do
    it { should exist }
    its('name') { should_not eq '1.2.3.4' }
    its('port') { should_not eq 5678 }
    its('noproxy') { should_not eq 'localhost' }
    its('noproxy') { should_not eq '127.0.0.1' }
  end

  describe jenkins_proxy('5.6.7.8:9012') do
    it { should exist }
    its('name') { should eq '5.6.7.8' }
    its('port') { should eq 9012 }
    its('noproxy') { should include 'nohost' }
    its('noproxy') { should include '*.nodomain' }
  end
end
