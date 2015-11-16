require 'spec_helper'

describe jenkins_user('chef') do
  it { should be_a_jenkins_user }
  it { should have_full_name('Chef Client') }
end

describe jenkins_plugin('greenballs') do
  it { should be_a_jenkins_plugin }
end

describe jenkins_user('random-bob') do
  it { should be_a_jenkins_user }
end
