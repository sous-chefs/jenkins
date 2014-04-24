require_relative '../../../kitchen/data/spec_helper'

describe jenkins_user('sethvargo') do
  it { should be_a_jenkins_user }
end

describe jenkins_user('schisamo') do
  it { should be_a_jenkins_user }
  it { should have_full_name('Seth Chisamore') }
  it { should have_email('schisamo@getchef.com') }
  it { should have_public_key('ssh-rsa AAAAAAA') }
end
