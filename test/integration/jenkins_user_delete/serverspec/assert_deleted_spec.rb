require_relative '../../../kitchen/data/spec_helper'

describe jenkins_user('sethvargo') do
  it { should_not exist }
end

describe jenkins_user('schisamo') do
  it { should_not exist }
end
