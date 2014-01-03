require_relative '../../../kitchen/data/spec_helper'

describe jenkins_slave('grimlock') do
  it { should be_a_jenkins_slave }
  it { should have_description('full of cesium salami') }
  it { should have_remote_fs('/tmp/jenkins/slaves/grimlock') }
  it { should have_labels(%w{ transformer autobot dinobot }) }
end

describe jenkins_slave('starscream') do
  it { should be_a_jenkins_slave }
  it { should have_description('should be the leader') }
  it { should have_remote_fs('/tmp/jenkins/slaves/starscream') }
  it { should have_labels(%w{ transformer decepticon seeker }) }
  it { should have_host('localhost') }
  it { should have_port(22) }
  it { should have_credentials('jenkins') }
end

describe jenkins_slave('skywarp') do
  it { should be_a_jenkins_slave }
  it { should have_remote_fs('/tmp/jenkins/slaves/skywarp') }
  it { should have_labels(%w{ transformer decepticon seeker }) }
  it { should have_host('localhost') }
  it { should have_port(22) }
  it { should have_credentials('38537014-ec66-49b5-aff2-aed1c19e2989') }
end

describe jenkins_slave('thundercracker') do
  it { should be_a_jenkins_slave }
  it { should have_remote_fs('/tmp/jenkins/slaves/thundercracker') }
  it { should have_labels(%w{ transformer decepticon seeker }) }
  it { should have_host('localhost') }
  it { should have_port(22) }
  it { should have_credentials('jenkins') }
end

describe jenkins_slave('soundwave') do
  it { should be_a_jenkins_slave }
  it { should have_description('casettes are still cool') }
  it { should have_remote_fs('/tmp/jenkins/slaves/soundwave') }
  it { should have_usage_mode('exclusive') }
  it { should have_availability('demand') }
  it { should have_in_demand_delay(1) }
  it { should have_idle_delay(3) }
  it { should have_labels(%w{ transformer decepticon badass }) }
end

describe jenkins_slave('shrapnel') do
  it { should be_a_jenkins_slave }
  it { should have_description('bugs are cool') }
  it { should have_remote_fs('/tmp/jenkins/slaves/shrapnel') }
  it { should have_labels(%w{ transformer decepticon insecticon }) }
  it { should have_environment(FOO: 'bar', BAZ: 'qux') }
end
