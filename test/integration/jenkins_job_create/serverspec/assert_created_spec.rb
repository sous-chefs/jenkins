require 'spec_helper'

describe jenkins_job('simple-execute') do
  it { should be_a_jenkins_job }
  it { should have_command('echo "This is Jenkins! Hear me roar!"') }
end
