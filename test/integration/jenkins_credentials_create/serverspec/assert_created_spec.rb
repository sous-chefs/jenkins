require_relative '../../../kitchen/data/spec_helper'

describe jenkins_credentials('schisamo') do
  it { should be_a_jenkins_credentials }
  it { should have_description('passwords are for suckers') }
  it { should have_password('superseekret') }
end

describe jenkins_credentials('schisamo2') do
  it { should be_a_jenkins_credentials }
  it { should have_id('63e11302-d446-4ba0-8aa4-f5821f74d36f') }
  it { should have_password('superseekret') }
end

describe jenkins_credentials('jenkins') do
  it { should be_a_jenkins_credentials }
  it { should have_description('this is more like it') }
  it { should have_private_key(File.read(File.expand_path('../../../../kitchen/data/data/test_id_rsa', __FILE__))) }
end

describe jenkins_credentials('jenkins2') do
  it { should be_a_jenkins_credentials }
  it { should have_private_key(File.read(File.expand_path('../../../../kitchen/data/data/test_id_rsa_with_passphrase', __FILE__)), 'secret') }
  it { should have_passphrase('secret') }
end
