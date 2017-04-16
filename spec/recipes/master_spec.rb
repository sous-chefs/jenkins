require 'spec_helper'

describe 'jenkins::_master_war' do
  context '(default) system account is false' do
    let(:home)          { '/opt/bacon' }
    let(:log_directory) { '/opt/bacon/log' }
    let(:user)          { 'bacon' }
    let(:group)         { 'meats' }

    cached(:chef_run) do
      ChefSpec::ServerRunner.new do |node|
        node.normal['jenkins']['master']['home']           = home
        node.normal['jenkins']['master']['log_directory']  = log_directory
        node.normal['jenkins']['master']['user']           = user
        node.normal['jenkins']['master']['group']          = group
        node.normal['jenkins']['master']['install_method'] = 'war'
      end.converge(described_recipe)
    end

    before do
      allow_any_instance_of(Chef::Recipe).to receive(:include_recipe)
    end

    it 'creates the user' do
      expect(chef_run).to create_user(user)
        .with_home(home)
    end

    it 'creates the group' do
      expect(chef_run).to create_group(group)
        .with_members([user])
    end

    it 'creates the home directory' do
      expect(chef_run).to create_directory(home)
        .with_owner(user)
        .with_group(group)
        .with_mode('0755')
        .with_recursive(true)
    end

    it 'creates the log directory' do
      expect(chef_run).to create_directory(log_directory)
        .with_owner(user)
        .with_group(group)
        .with_mode('0755')
        .with_recursive(true)
    end
  end

  context 'system account is true' do
    let(:home)          { '/opt/bacon' }
    let(:log_directory) { '/opt/bacon/log' }
    let(:user)          { 'bacon' }
    let(:group)         { 'meats' }

    cached(:chef_run) do
      ChefSpec::ServerRunner.new do |node|
        node.normal['jenkins']['master']['home']           = home
        node.normal['jenkins']['master']['log_directory']  = log_directory
        node.normal['jenkins']['master']['user']           = user
        node.normal['jenkins']['master']['group']          = group
        node.normal['jenkins']['master']['install_method'] = 'war'
        node.normal['jenkins']['master']['use_system_accounts'] = true
      end.converge(described_recipe)
    end

    before do
      allow_any_instance_of(Chef::Recipe).to receive(:include_recipe)
    end

    it 'creates the user' do
      expect(chef_run).to create_user(user)
        .with_home(home)
        .with(system: true)
    end

    it 'creates the group' do
      expect(chef_run).to create_group(group)
        .with_members([user])
        .with(system: true)
    end

    it 'creates the home directory' do
      expect(chef_run).to create_directory(home)
        .with_owner(user)
        .with_group(group)
        .with_mode('0755')
        .with_recursive(true)
    end

    it 'creates the log directory' do
      expect(chef_run).to create_directory(log_directory)
        .with_owner(user)
        .with_group(group)
        .with_mode('0755')
        .with_recursive(true)
    end
  end  
end
describe 'jenkins::_master_package' do
  context 'jenkins user is set' do
    let(:home)          { '/opt/bacon' }
    let(:log_directory) { '/opt/bacon/log' }
    let(:user)          { 'bacon' }
    let(:group)         { 'meats' }

    cached(:chef_run) do
      ChefSpec::ServerRunner.new(platform: 'centos', version: '6.5') do |node|
        node.set['jenkins']['master']['home']           = home
        node.set['jenkins']['master']['log_directory']  = log_directory
        node.set['jenkins']['master']['user']           = user
        node.set['jenkins']['master']['group']          = group
        node.set['jenkins']['master']['install_method'] = 'package'
        node.set['jenkins']['master']['use_system_accounts'] = true

        # Workaround until https://github.com/hw-cookbooks/runit/pull/57 is merged.
        node.set[:runit][:sv_bin] = '/usr/bin/sv'
      end.converge(described_recipe)
    end

    before do
      allow_any_instance_of(Chef::Recipe).to receive(:include_recipe)
    end

    it 'sets the jenkins user in /etc/sysconfig/jenkins' do
      expect(chef_run).to render_file('/etc/sysconfig/jenkins').with_content('JENKINS_USER="bacon"')
    end
  end
end