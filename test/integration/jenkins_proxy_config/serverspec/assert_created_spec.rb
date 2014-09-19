require_relative '../../../kitchen/data/spec_helper'

describe jenkins_proxy('1.2.3.4:5678') do
  it { should be_a_jenkins_proxy }
  it { should_not have_name('1.2.3.4') }
  it { should_not have_port(5678) }
  it { should_not have_noproxy('localhost') }
  it { should_not have_noproxy('127.0.0.1') }
end

describe jenkins_proxy('5.6.7.8:9012') do
  it { should be_a_jenkins_proxy }
  it { should have_name('5.6.7.8') }
  it { should have_port(9012) }
  it { should have_noproxy('nohost') }
  it { should have_noproxy('*.nodomain') }
end
