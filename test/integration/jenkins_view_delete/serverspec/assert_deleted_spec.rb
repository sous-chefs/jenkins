require_relative '../../../kitchen/data/spec_helper'

%w(test1 test2).each do
  it { should_not be_a_jenkins_view }
end
