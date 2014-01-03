require_relative '../../../kitchen/data/spec_helper'

%w{
  grimlock
  starscream
  skywarp
  thundercracker
  soundwave
  shrapnel
}.each do |slave_name|

  describe jenkins_slave(slave_name) do
    it { should_not be_a_jenkins_slave }
  end

end
