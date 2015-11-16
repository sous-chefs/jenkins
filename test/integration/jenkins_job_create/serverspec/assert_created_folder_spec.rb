require 'spec_helper'

describe jenkins_job('my-folder') do
  it { should be_a_jenkins_job }
  it { should have_plugin_like(/^cloudbees-folder/) }
end
