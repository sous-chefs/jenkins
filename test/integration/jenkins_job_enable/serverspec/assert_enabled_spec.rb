require 'spec_helper'

describe jenkins_job('my-project') do
  it { should be_enabled }
end
