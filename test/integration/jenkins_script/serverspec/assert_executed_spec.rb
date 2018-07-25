require 'spec_helper'

describe jenkins_user('yzl') do
  it { should be_a_jenkins_user }
  it { should have_full_name('Yvonne Lam') }
  it { should have_email('yzl@chef.io') }
end

describe jenkins_user('badger') do
  it { should be_a_jenkins_user }
  it { should have_full_name('Badger Badger') }
  it { should have_email('badger@chef.io') }
end

describe jenkins_user('foo') do
  it { should be_a_jenkins_user }
  it { should have_full_name('Foo Foo') }
  it { should have_email('foo@chef.io') }
end
