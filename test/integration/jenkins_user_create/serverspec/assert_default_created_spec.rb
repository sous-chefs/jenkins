require_relative '../../../kitchen/data/spec_helper'

describe jenkins_user('sethvargo') do
  it { should be_a_jenkins_user }
end
