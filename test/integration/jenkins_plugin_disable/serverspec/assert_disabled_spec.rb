require_relative '../../../kitchen/data/spec_helper'

describe jenkins_plugin('greenballs') do
  it { should be_disabled }
end
