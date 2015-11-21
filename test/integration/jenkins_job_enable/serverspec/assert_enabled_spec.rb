require 'spec_helper'

describe jenkins_job('simple-execute') do
  it { should be_enabled }
end
