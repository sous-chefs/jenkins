require 'spec_helper'

%w(schisamo schisamo2 schisamo3 jenkins jenkins2 jenkins3 dollarbills_secret).each do |name|
  describe jenkins_user_credentials(name) do
    it { should_not be_a_jenkins_credentials }
  end
end

describe jenkins_sauce_ondemand_credentials('Sauce OnDemand test credentials') do
  it { should_not be_a_jenkins_credentials }
end

describe jenkins_blazemeter_credentials('BlazeMeter credentials description') do
  it { should_not be_a_jenkins_credentials }
end
