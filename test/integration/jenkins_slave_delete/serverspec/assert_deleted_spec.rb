require_relative '../../../kitchen/data/spec_helper'

# JNLP Slaves
%w{
  grimlock
  soundwave
  shrapnel
}.each do |slave_name|

  describe jenkins_slave(slave_name) do
    it { should_not be_a_jenkins_slave }
  end

  describe service("jenkins-slave-#{slave_name}") do
    it { should_not be_running }
  end

end

# SSH Slaves
%w{
  starscream
  skywarp
  thundercracker
}.each do |slave_name|

  describe jenkins_slave(slave_name) do
    it { should_not be_a_jenkins_slave }
  end

end
