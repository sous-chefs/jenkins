require 'spec_helper'

describe jenkins_plugin('greenballs') do
  it { should be_enabled }
end
