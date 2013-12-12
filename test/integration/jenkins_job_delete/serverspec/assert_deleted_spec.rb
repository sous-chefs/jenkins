require_relative '../../../kitchen/data/spec_helper'

describe jenkins_job('my-project') do
  it { should_not exist }
end

describe jenkins_job('non-existent-job') do
  it { should_not exist }
end
