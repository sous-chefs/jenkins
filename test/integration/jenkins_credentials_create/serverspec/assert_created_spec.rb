require 'spec_helper'

describe jenkins_user_credentials('schisamo') do
  it { should be_a_jenkins_credentials }
  it { should have_description('passwords are for suckers') }
  it { should have_password('superseekret') }
end

describe jenkins_user_credentials('schisamo2') do
  it { should be_a_jenkins_credentials }
  it { should have_id('63e11302-d446-4ba0-8aa4-f5821f74d36f') }
  it { should have_password('superseekret') }
end

describe jenkins_user_credentials('schisamo3') do
  it { should be_a_jenkins_credentials }
  it { should have_id('schisamo3') }
  it { should have_password('superseekret') }
end

describe jenkins_user_credentials('jenkins') do
  it { should be_a_jenkins_credentials }
  it { should have_description('this is more like it') }
  it { should have_private_key(File.read("#{fixture_data_base_path}/test_id_rsa")) }
end

describe jenkins_user_credentials('jenkins2') do
  it { should be_a_jenkins_credentials }
  it { should have_private_key(File.read("#{fixture_data_base_path}/test_id_rsa_with_passphrase"), 'secret') }
  it { should have_passphrase('secret') }
end

describe jenkins_user_credentials('jenkins3') do
  it { should be_a_jenkins_credentials }
  it { should have_description('I specified an ID') }
  it { should have_id('766952b8-e1ea-4ee1-b769-e159681cb893') }
  it { should have_private_key(File.read("#{fixture_data_base_path}/test_id_rsa")) }
end

describe jenkins_user_credentials('ecdsa_nopasswd') do
  it { should be_a_jenkins_credentials }
  it { should have_private_key(File.read("#{fixture_data_base_path}/test_id_ecdsa")) }
end

describe jenkins_user_credentials('ecdsa_passwd') do
  it { should be_a_jenkins_credentials }
  it { should have_private_key(File.read("#{fixture_data_base_path}/test_id_ecdsa_with_passphrase"), 'secret') }
  it { should have_passphrase('secret') }
end

describe jenkins_user_credentials('dollarbills') do
  it { should be_a_jenkins_credentials }
  it { should have_password('$uper$ecret') }
end

describe jenkins_secret_text_credentials('dollarbills_secret') do
  it { should be_a_jenkins_credentials }
  it { should have_secret('$uper$ecret') }
end
