require 'spec_helper'

describe 'jenkins::_node_jnlp' do
  let(:chef_run) do
    ChefSpec::ChefRunner.new(platform: 'ubuntu', version: '12.04').converge('jenkins::_node_jnlp')
  end

  it 'includes java' do
    expect(chef_run).to include_recipe('java::default')
  end

  it 'includes runit' do
    expect(chef_run).to include_recipe('runit::default')
  end

  it 'creates the jenkins group' do
    expect(chef_run).to create_group('jenkins-node')
  end

  it 'creates the jenkins user' do
    expect(chef_run).to create_user('jenkins-node')
    expect(chef_run.user('jenkins-node').comment).to eq('Jenkins CI node (jnlp)')
    expect(chef_run.user('jenkins-node').gid).to eq('jenkins-node')
    expect(chef_run.user('jenkins-node').home).to eq('/home/jenkins')
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

  it 'creates the jenkins node' do
    expect(chef_run).to create_jenkins_node('fauxhai.local').with(
      description:  'ubuntu 12.04 [GNU/Linux 3.2.0-26-generic x86_64] slave on Fauxhai',
      executors:    1,
      remote_fs:    '/home/jenkins',
      labels:       [],
      mode:         'normal',
      launcher:     'jnlp',
      availability: 'always'
    )
  end

  it 'downloads the slave.jar' do
    expect(chef_run).to create_remote_file('/home/jenkins/slave.jar')
  end

  it 'executes the jenkins_cli' do
    expect(chef_run).to run_jenkins_cli('node_info for fauxhai.local to get jnlp secret').with(
      command: 'groovy node_info.groovy fauxhai.local'
    )
  end
end
