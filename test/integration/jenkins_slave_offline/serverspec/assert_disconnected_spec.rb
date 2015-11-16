require 'spec_helper'

%w(builder executor smoke).each do |name|
  describe jenkins_slave(name) do
    it { should be_a_jenkins_slave }
    it { should_not be_online }
    it { should have_offline_reason "Autobots beat #{name}" }
  end
end
