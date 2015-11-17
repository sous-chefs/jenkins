require 'spec_helper'

%w(builder executor smoke).each do |name|
  describe jenkins_slave(name) do
    it { should be_a_jenkins_slave }
    it { should be_connected }
    it { should be_online }
  end
end
