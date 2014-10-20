require_relative '../../../kitchen/data/spec_helper'

describe jenkins_user('test1') do
  it { should be_a_jenkins_view }
end

describe jenkins_user('test2') do
  it { should be_a_jenkins_view }
  it { should have_regex('test2.*') }
end