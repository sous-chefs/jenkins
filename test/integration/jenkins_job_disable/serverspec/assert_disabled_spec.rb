require 'spec_helper'

describe jenkins_job('simple-execute') do
  it { should be_disabled }
end

describe jenkins_job('execute-with-params') do
  it { should be_enabled }
end
