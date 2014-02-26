require 'spec_helper'

describe 'jenkins::master' do
  let(:home)          { '/opt/bacon' }
  let(:log_directory) { '/opt/bacon/log' }
  let(:user)          { 'bacon' }
  let(:group)         { 'meats' }

  cached(:chef_run) do
    ChefSpec::Runner.new do |node|
      node.set['jenkins']['master']['home']          = home
      node.set['jenkins']['master']['log_directory'] = log_directory
      node.set['jenkins']['master']['user']          = user
      node.set['jenkins']['master']['group']         = group
    end.converge(described_recipe)
  end

  before do
    Chef::Recipe.any_instance.stub(:include_recipe)
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
