require_relative '../../../kitchen/data/spec_helper'

describe jenkins_proxy('1.2.3.4:5678') do
  it { should_not be_a_jenkins_proxy }
end

describe jenkins_proxy('5.6.7.8:9012') do
  it { should_not be_a_jenkins_proxy }
end
