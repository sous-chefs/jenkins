require 'spec_helper'

describe jenkins_plugin('greenballs') do
  it { should_not be_a_jenkins_plugin }
end

describe jenkins_plugin('non-existent-plugin') do
  it { should_not be_a_jenkins_plugin }
end
