require_relative '../../../kitchen/data/spec_helper'

%w{
  starscream
  skywarp
  thundercracker
}.each do |slave_name|

  describe jenkins_slave(slave_name) do
    it { should be_a_jenkins_slave }
    it { should_not be_online }
    it { should have_offline_reason "Autobots beat #{slave_name}" }
  end

end
