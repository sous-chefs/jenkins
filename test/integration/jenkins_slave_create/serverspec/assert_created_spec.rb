require_relative '../../../kitchen/data/spec_helper'

#
# JNLP Slave #1
# ------------------------------
describe jenkins_slave('builder') do
  it { should be_a_jenkins_slave }
  it { should have_description('A generic slave builder') }
  it { should have_remote_fs('/tmp/jenkins/slaves/builder') }
  it { should have_labels(%w[builder linux]) }
  it { should be_connected }
  it { should be_online }
end

describe group('jenkins-builder') do
  it { should exist }
end

describe user('jenkins-builder') do
  it { should exist }
  it { should belong_to_group('jenkins-builder') }
end

describe file('/tmp/jenkins/slaves/builder') do
  it { should be_directory }
end

describe service('jenkins-slave-builder') do
  it { should be_running }
end

#
# JNLP Slave #2
# ------------------------------
describe jenkins_slave('smoke') do
  it { should be_a_jenkins_slave }
  it { should have_description('Run high-level integration tests') }
  it { should have_remote_fs('/tmp/jenkins/slaves/smoke') }
  it { should have_usage_mode('exclusive') }
  it { should have_availability('demand') }
  it { should have_in_demand_delay(1) }
  it { should have_idle_delay(3) }
  it { should have_labels(%w[runner fast]) }
  it { should be_connected }
  it { should be_online }
end

describe group('jenkins-smoke') do
  it { should exist }
end

describe user('jenkins-smoke') do
  it { should exist }
  it { should belong_to_group('jenkins-smoke') }
end

describe file('/tmp/jenkins/slaves/smoke') do
  it { should be_directory }
end

describe service('jenkins-slave-smoke') do
  it { should be_running }
end

#
# JNLP Slave #3
# ------------------------------
describe jenkins_slave('executor') do
  it { should be_a_jenkins_slave }
  it { should have_description('Run test suites') }
  it { should have_remote_fs('/tmp/jenkins/slaves/executor') }
  it { should have_labels(%w[executor freebsd jail]) }
  it { should have_environment(FOO: 'bar', BAZ: 'qux') }
  it { should be_connected }
  it { should be_online }
end

describe group('jenkins-executor') do
  it { should exist }
end

describe user('jenkins-executor') do
  it { should exist }
  it { should belong_to_group('jenkins-executor') }
end

describe file('/tmp/jenkins/slaves/executor') do
  it { should be_directory }
end

describe service('jenkins-slave-executor') do
  it { should be_running }
end

#
# SSH Slave #1
# ------------------------------
describe jenkins_slave('ssh-builder') do
  it { should be_a_jenkins_slave }
  it { should have_description('Builder, but over SSH') }
  it { should have_remote_fs('/tmp/jenkins/slaves/ssh-builder') }
  it { should have_labels(%w[builer linux]) }
  it { should have_host('localhost') }
  it { should have_port(22) }
  it { should have_credentials('jenkins-ssh-builder') }
  it { should be_connected }
  it { should be_online }
end

describe group('jenkins-ssh-builder') do
  it { should exist }
end

describe user('jenkins-ssh-builder') do
  it { should exist }
  it { should belong_to_group('jenkins-ssh-builder') }
end

describe file('/tmp/jenkins/slaves/ssh-builder') do
  it { should be_directory }
end

#
# SSH Slave #2
# ------------------------------
describe jenkins_slave('ssh-executor') do
  it { should be_a_jenkins_slave }
  it { should have_remote_fs('/tmp/jenkins/slaves/ssh-executor') }
  it { should have_labels(%w[ssh-executor freebsd jail]) }
  it { should have_host('localhost') }
  it { should have_port(22) }
  it { should have_credentials('38537014-ec66-49b5-aff2-aed1c19e2989') }
  it { should be_connected }
  it { should be_online }
end

describe group('jenkins-ssh-executor') do
  it { should exist }
end

describe user('jenkins-ssh-executor') do
  it { should exist }
  it { should belong_to_group('jenkins-ssh-executor') }
end

describe file('/tmp/jenkins/slaves/ssh-executor') do
  it { should be_directory }
end

#
# SSH Slave #3
# ------------------------------
describe jenkins_slave('ssh-smoke') do
  it { should be_a_jenkins_slave }
  it { should have_remote_fs('/tmp/jenkins/slaves/ssh-smoke') }
  it { should have_labels(%w[runner fast]) }
  it { should have_host('localhost') }
  it { should have_port(22) }
  it { should have_credentials('jenkins-ssh-smoke') }
  it { should be_connected }
  it { should be_online }
end

describe group('jenkins-ssh-smoke') do
  it { should exist }
end

describe user('jenkins-ssh-smoke') do
  it { should exist }
  it { should belong_to_group('jenkins-ssh-smoke') }
end

describe file('/tmp/jenkins/slaves/ssh-smoke') do
  it { should be_directory }
end
