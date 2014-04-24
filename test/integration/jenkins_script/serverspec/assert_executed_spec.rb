require_relative '../../../kitchen/data/spec_helper'

describe jenkins_user('yzl') do
  it { should be_a_jenkins_user }
  it { should have_full_name('Yvonne Lam') }
  it { should have_email('yzl@getchef.com') }
end
