require_relative '../../../kitchen/data/spec_helper'

describe jenkins_job('my-project') do
  it { should exist }
  it { should have_command('echo "This is Jenkins! Hear me roar!"') }
end
