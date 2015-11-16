require 'spec_helper'

# JNLP Slaves
%w(builder executor smoke).each do |name|
  describe jenkins_slave(name) do
    it { should_not be_a_jenkins_slave }
  end

  describe service("jenkins-slave-#{name}") do
    it { should_not be_running }
  end
end

# SSH Slaves
%w(ssh-builder ssh-executor ssh-smoke).each do |name|
  describe jenkins_slave(name) do
    it { should_not be_a_jenkins_slave }
  end
end
