require_relative '../../../kitchen/data/spec_helper'

%w(schisamo schisamo2 schisamo3 jenkins jenkins2 jenkins3).each do |username|
  describe jenkins_credentials(username) do
    it { should_not be_a_jenkins_credentials }
  end
end
