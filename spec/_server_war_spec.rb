require 'spec_helper'

describe 'jenkins::_server_war' do
  before do
    # This recipe notifies a resource that exists in another recipe
    Chef::Resource::Notification.any_instance.stub(:fix_resource_reference)
  end

  let(:chef_run) do
    ChefSpec::ChefRunner.new(platform: 'ubuntu', version: '12.04').converge('jenkins::_server_war')
  end

  it 'installs runit' do
    expect(chef_run).to include_recipe('runit::default')
  end

  it 'downloads the war file' do
    expect(chef_run).to create_remote_file('/var/lib/jenkins/jenkins.war').with(
      source: 'http://mirrors.jenkins-ci.org/war/latest/jenkins.war',
      owner:  'jenkins',
      group:  'nogroup'
    )
  end
end
