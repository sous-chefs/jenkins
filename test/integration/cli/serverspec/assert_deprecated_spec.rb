require 'serverspec'
include Serverspec::Helper::Exec
include Serverspec::Helper::DetectOS

describe 'jenkins_cli' do
  describe file('/var/log/chef.log') do
    it { should contain '[DEPRECATED] jenkins_cli is deprecated' }
  end
end
