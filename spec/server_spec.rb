require 'spec_helper'

describe 'jenkins::server' do
  let(:chef_run) do
    ChefSpec::ChefRunner.new(platform: 'ubuntu', version: '12.04').converge('jenkins::server')
  end

  it 'installs java' do
    expect(chef_run).to include_recipe('java::default')
  end

  it 'creates the jenkins user' do
    expect(chef_run).to create_user('jenkins')
    expect(chef_run.user('jenkins').home).to eq('/var/lib/jenkins')
  end

  ['/var/lib/jenkins', '/var/lib/jenkins/plugins', '/var/log/jenkins', '/var/lib/jenkins/.ssh'].each do |dir|
    context "#{dir} directory" do
      let(:directory) { chef_run.directory(dir) }

      it 'creates the directory' do
        expect(chef_run).to create_directory(dir)
      end

      it 'is owned by jenkins:nogroup' do
        expect(directory.owner).to eq('jenkins')
        expect(directory.group).to eq('nogroup')
      end

      it 'has 0700 permissions' do
        expect(directory.mode).to eq('0700')
      end
    end
  end

  context 'ssh key' do
    let(:command) { chef_run.execute("ssh-keygen -f /var/lib/jenkins/.ssh/id_rsa -N ''") }

    it 'generates an SSH key' do
      expect(chef_run).to execute_command("ssh-keygen -f /var/lib/jenkins/.ssh/id_rsa -N ''")
    end

    it 'is run as jenkins:nogroup' do
      expect(command.user).to eq('jenkins')
      expect(command.group).to eq('nogroup')
    end

    it 'notifies the ruby block to store the key' do
      expect(command).to notify('ruby_block[store_server_ssh_pubkey]', :create)
    end
  end
end
