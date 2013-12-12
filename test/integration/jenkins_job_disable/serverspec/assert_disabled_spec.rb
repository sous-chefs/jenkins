require_relative '../../../kitchen/data/spec_helper'

describe jenkins_job('my-project') do
  it { should be_disabled }
end
