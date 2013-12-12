require_relative '../../../kitchen/data/spec_helper'

describe service('jenkins') do
  it { should_not be_running }
end
