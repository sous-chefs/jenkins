require 'spec_helper'

describe jenkins_plugin('greenballs') do
  it { should be_a_jenkins_plugin }
end

describe jenkins_user('random-bob') do
  it { should be_a_jenkins_user }
end
