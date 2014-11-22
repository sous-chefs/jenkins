require_relative '../../../kitchen/data/spec_helper'

describe jenkins_plugin('greenballs') do
  it { should be_a_jenkins_plugin }
end

describe jenkins_plugin('disk-usage') do
  it { should be_a_jenkins_plugin }
  it { should have_version('0.23') }
end

describe jenkins_plugin('copy-to-slave') do
  it { should be_a_jenkins_plugin }
  it { should have_version('1.4.3') }
end

describe jenkins_plugin('github-oauth') do
  it { should be_a_jenkins_plugin }
  it { should have_version('0.20') }
end

# Ensure one of github-oauth's deps was installed
describe jenkins_plugin('github-api') do
  it { should be_a_jenkins_plugin }
end
