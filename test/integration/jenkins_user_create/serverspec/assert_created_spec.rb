require 'spec_helper'

describe jenkins_user('sethvargo') do
  it { should be_a_jenkins_user }
end

describe jenkins_user('schisamo') do
  it { should be_a_jenkins_user }
  it { should have_full_name('Seth Chisamore') }
  it { should have_email('schisamo@chef.io') }
  it { should have_public_key('ssh-rsa AAAAAAA') }
end

describe jenkins_user('valyukov') do
  it { should be_a_jenkins_user }
  its(:password_hash) { should start_with '#jbcrypt:' }
  it { should have_public_key('ssh-rsa BBBBBBB') }
  it { should have_public_key('ssh-rsa CCCCCCC') }
end
