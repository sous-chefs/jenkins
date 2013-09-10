require 'spec_helper'

describe 'jenkins::iptables' do
  let(:chef_run) do
    ChefSpec::ChefRunner.new(platform: 'ubuntu', version: '12.04').converge('jenkins::iptables')
  end

  it 'installs iptables' do
    expect(chef_run).to include_recipe('iptables::default')
  end

  context 'on unsupported platforms' do
    let(:chef_run) do
      ChefSpec::ChefRunner.new(platform: 'windows', version: '2008R2').converge('jenkins::iptables')
    end

    it 'does nothing' do
      expect(chef_run).to_not include_recipe('iptables::default')
    end
  end
end
