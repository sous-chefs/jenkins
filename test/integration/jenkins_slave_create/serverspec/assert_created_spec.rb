require_relative '../../../kitchen/data/spec_helper'

##################################################
# JNLP Slave #1
##################################################
describe jenkins_slave('grimlock') do
  it { should be_a_jenkins_slave }
  it { should have_description('full of cesium salami') }
  it { should have_remote_fs('/tmp/jenkins/slaves/grimlock') }
  it { should have_labels(%w{ transformer autobot dinobot }) }
  it { should be_connected }
  it { should be_online }
end

describe group('jenkins-grimlock') do
  it { should exist }
end

describe user('jenkins-grimlock') do
  it { should exist }
  it { should belong_to_group 'jenkins-grimlock' }
end

describe file('/tmp/jenkins/slaves/grimlock') do
  it { should be_directory }
end

describe service('jenkins-slave-grimlock') do
  it { should be_running }
end

##################################################
# JNLP Slave #2
##################################################
describe jenkins_slave('soundwave') do
  it { should be_a_jenkins_slave }
  it { should have_description('casettes are still cool') }
  it { should have_remote_fs('/tmp/jenkins/slaves/soundwave') }
  it { should have_usage_mode('exclusive') }
  it { should have_availability('demand') }
  it { should have_in_demand_delay(1) }
  it { should have_idle_delay(3) }
  it { should have_labels(%w{ transformer decepticon badass }) }
  it { should be_connected }
  it { should be_online }
end

describe group('jenkins-soundwave') do
  it { should exist }
end

describe user('jenkins-soundwave') do
  it { should exist }
  it { should belong_to_group 'jenkins-soundwave' }
end

describe file('/tmp/jenkins/slaves/soundwave') do
  it { should be_directory }
end

describe service('jenkins-slave-soundwave') do
  it { should be_running }
end

##################################################
# JNLP Slave #3
##################################################
describe jenkins_slave('shrapnel') do
  it { should be_a_jenkins_slave }
  it { should have_description('bugs are cool') }
  it { should have_remote_fs('/tmp/jenkins/slaves/shrapnel') }
  it { should have_labels(%w{ transformer decepticon insecticon }) }
  it { should have_environment(FOO: 'bar', BAZ: 'qux') }
  it { should be_connected }
  it { should be_online }
end

describe group('jenkins-shrapnel') do
  it { should exist }
end

describe user('jenkins-shrapnel') do
  it { should exist }
  it { should belong_to_group 'jenkins-shrapnel' }
end

describe file('/tmp/jenkins/slaves/shrapnel') do
  it { should be_directory }
end

describe service('jenkins-slave-shrapnel') do
  it { should be_running }
end

##################################################
# SSH Slave #1
##################################################
describe jenkins_slave('starscream') do
  it { should be_a_jenkins_slave }
  it { should have_description('should be the leader') }
  it { should have_remote_fs('/tmp/jenkins/slaves/starscream') }
  it { should have_labels(%w{ transformer decepticon seeker }) }
  it { should have_host('localhost') }
  it { should have_port(22) }
  it { should have_credentials('jenkins-starscream') }
  it { should be_connected }
  it { should be_online }
end

describe group('jenkins-starscream') do
  it { should exist }
end

describe user('jenkins-starscream') do
  it { should exist }
  it { should belong_to_group 'jenkins-starscream' }
end

describe file('/tmp/jenkins/slaves/starscream') do
  it { should be_directory }
end

##################################################
# SSH Slave #2
##################################################
describe jenkins_slave('skywarp') do
  it { should be_a_jenkins_slave }
  it { should have_remote_fs('/tmp/jenkins/slaves/skywarp') }
  it { should have_labels(%w{ transformer decepticon seeker }) }
  it { should have_host('localhost') }
  it { should have_port(22) }
  it { should have_credentials('38537014-ec66-49b5-aff2-aed1c19e2989') }
  it { should be_connected }
  it { should be_online }
end

describe group('jenkins-skywarp') do
  it { should exist }
end

describe user('jenkins-skywarp') do
  it { should exist }
  it { should belong_to_group 'jenkins-skywarp' }
end

describe file('/tmp/jenkins/slaves/skywarp') do
  it { should be_directory }
end

##################################################
# SSH Slave #3
##################################################
describe jenkins_slave('thundercracker') do
  it { should be_a_jenkins_slave }
  it { should have_remote_fs('/tmp/jenkins/slaves/thundercracker') }
  it { should have_labels(%w{ transformer decepticon seeker }) }
  it { should have_host('localhost') }
  it { should have_port(22) }
  it { should have_credentials('jenkins-thundercracker') }
  it { should be_connected }
  it { should be_online }
end

describe group('jenkins-thundercracker') do
  it { should exist }
end

describe user('jenkins-thundercracker') do
  it { should exist }
  it { should belong_to_group 'jenkins-thundercracker' }
end

describe file('/tmp/jenkins/slaves/thundercracker') do
  it { should be_directory }
end
