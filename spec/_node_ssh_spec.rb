require 'spec_helper'

describe 'jenkins::_node_ssh' do
  let(:chef_run) do
    ChefSpec::ChefRunner.new(platform: 'ubuntu', version: '12.04').converge('jenkins::_node_ssh')
  end

  it 'includes java' do
    expect(chef_run).to include_recipe('java::default')
  end

  it 'creates the jenkins group' do
    expect(chef_run).to create_group('jenkins-node')
  end

  it 'creates the jenkins user' do
    expect(chef_run).to create_user('jenkins-node')
    expect(chef_run.user('jenkins-node').comment).to eq('Jenkins CI node (ssh)')
    expect(chef_run.user('jenkins-node').gid).to eq('jenkins-node')
    expect(chef_run.user('jenkins-node').home).to eq('/home/jenkins')
    expect(chef_run.user('jenkins-node').shell).to eq('/bin/sh')
  end

  context 'jenkins home directory (/home/jenkins)' do
    let(:directory) { chef_run.directory('/home/jenkins') }

    it 'creates the directory' do
      expect(chef_run).to create_directory('/home/jenkins')
    end

    it 'is owned by jenkins-node:jenkins-node' do
      expect(directory.owner).to eq('jenkins-node')
      expect(directory.group).to eq('jenkins-node')
    end
  end

  context 'jenkins ssh directory (/home/jenkins/.ssh)' do
    let(:directory) { chef_run.directory('/home/jenkins/.ssh') }

    it 'creates the directory' do
      expect(chef_run).to create_directory('/home/jenkins/.ssh')
    end

    it 'is owned by jenkins-node:jenkins-node' do
      expect(directory.owner).to eq('jenkins-node')
      expect(directory.group).to eq('jenkins-node')
    end

    it 'has 0700 permissions' do
      expect(directory.mode).to eq('0700')
    end
  end

  context 'jenkins authorized keys file' do
    let(:file) { chef_run.file('/home/jenkins/.ssh/authorized_keys') }

    it 'creates the file' do
      expect(chef_run).to create_file('/home/jenkins/.ssh/authorized_keys')
    end

    it 'is owned by jenkins-node:jenkins-node' do
      expect(file.owner).to eq('jenkins-node')
      expect(file.group).to eq('jenkins-node')
    end

    it 'has 0600 permissions' do
      expect(file.mode).to eq('0600')
    end
  end

  it 'creates the jenkins node' do
    expect(chef_run).to create_jenkins_node('fauxhai.local').with(
      description:  'ubuntu 12.04 [GNU/Linux 3.2.0-26-generic x86_64] slave on Fauxhai',
      executors:    1,
      remote_fs:    '/home/jenkins',
      labels:       [],
      mode:         'normal',
      launcher:     'ssh',
      availability: 'always',
      port:         22,
      username:     'jenkins-node'
    )
  end
end
