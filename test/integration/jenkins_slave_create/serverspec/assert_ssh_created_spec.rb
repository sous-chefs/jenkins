require_relative '../../../kitchen/data/spec_helper'

#
# SSH Slave #1
# ------------------------------
describe jenkins_slave('ssh-builder') do
  it { should be_a_jenkins_slave }
  it { should have_description('A builder, but over SSH') }
  it { should have_remote_fs('/tmp/slave-ssh-builder') }
  it { should have_labels(%w(builer linux)) }
  it { should have_host('localhost') }
  it { should have_port(22) }
  it { should have_credentials('jenkins-ssh-key') }
  it { should be_connected }
  it { should be_online }
end

#
# SSH Slave #2
# ------------------------------
describe jenkins_slave('ssh-executor') do
  it { should be_a_jenkins_slave }
  it { should have_description('An executor, but over SSH') }
  it { should have_remote_fs('/tmp/slave-ssh-executor') }
  it { should have_labels(%w(ssh-executor freebsd jail)) }
  it { should have_host('localhost') }
  it { should have_port(22) }
  it { should have_credentials('38537014-ec66-49b5-aff2-aed1c19e2989') }
  it { should be_connected }
  it { should be_online }
end

#
# SSH Slave #3
# ------------------------------
describe jenkins_slave('ssh-smoke') do
  it { should be_a_jenkins_slave }
  it { should have_description('A smoke tester, but over SSH') }
  it { should have_remote_fs('/home/jenkins-ssh-password') }
  it { should have_labels(%w(runner fast)) }
  it { should have_host('localhost') }
  it { should have_port(22) }
  it { should have_credentials('jenkins-ssh-password') }
  it { should be_connected }
  it { should be_online }
end
