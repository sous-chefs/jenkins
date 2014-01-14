require_relative '../../../kitchen/data/spec_helper'

describe jenkins_user('sethvargo') do
  it { should be_a_jenkins_user }
  it { should have_full_name('Seth Vargo') }
  it { should have_email('sethvargo@gmail.com') }
end
