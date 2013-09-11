require 'spec_helper'

describe 'jenkins::_server_package' do
  before do
    # This recipe notifies a resource that exists in another recipe
    Chef::Resource::Notification.any_instance.stub(:fix_resource_reference)
  end

  context 'on debian' do
    let(:chef_run) do
      ChefSpec::ChefRunner.new(platform: 'ubuntu', version: '12.04').converge('jenkins::_server_package')
    end

    it 'includes the apt recipe' do
      expect(chef_run).to include_recipe('apt::default')
    end

    it 'adds the apt repository' do
      pending
    end
  end

  context 'on redhat' do
    let(:chef_run) do
      ChefSpec::ChefRunner.new(platform: 'redhat', version: '6.3').converge('jenkins::_server_package')
    end

    it 'includes the yum recipe' do
      expect(chef_run).to include_recipe('yum::default')
    end

    it 'adds the yum repository' do
      pending
    end
  end

  let(:chef_run) do
    ChefSpec::ChefRunner.new(platform: 'ubuntu', version: '12.04').converge('jenkins::_server_package')
  end

  it 'installs jenkins' do
    expect(chef_run).to install_package('jenkins')
  end

  context '/etc/default/jenkins' do
    let(:template) { chef_run.template('/etc/default/jenkins') }

    it 'creates the template' do
      expect(chef_run).to create_file('/etc/default/jenkins')
    end

    it 'is owned by root:root' do
      expect(template.owner).to eq('root')
      expect(template.group).to eq('root')
    end

    it 'has 0644 permissions' do
      expect(template.mode).to eq('0644')
    end
  end

  it 'starts the jenkins service' do
    expect(chef_run).to start_service('jenkins')
    expect(chef_run).to set_service_to_start_on_boot('jenkins')
  end
end
