require 'spec_helper'

describe jenkins_user('sethvargo') do
  it { should_not be_a_jenkins_user }
end

describe jenkins_user('schisamo') do
  it { should_not be_a_jenkins_user }
end
