require 'spec_helper'

describe 'jenkins::java' do
  context 'on Debian' do
    cached(:chef_run) do
      ChefSpec::Runner.new(platform: 'debian', version: '7.1')
        .converge(described_recipe)
    end

    it 'installs openjdk-7-jdk' do
      expect(chef_run).to install_package('openjdk-7-jdk')
    end
  end

  context 'on RHEL' do
    cached(:chef_run) do
      ChefSpec::Runner.new(platform: 'redhat', version: '6.5')
        .converge(described_recipe)
    end

    it 'installs java-1.7.0-openjdk' do
      expect(chef_run).to install_package('java-1.7.0-openjdk')
    end
  end

  context 'on an unsupported platform' do
    cached(:chef_run) do
      ChefSpec::Runner.new(platform: 'mac_os_x', version: '10.8.2')
        .converge(described_recipe)
    end

    it 'raises an exception' do
      expect { chef_run }
        .to raise_error(RuntimeError, "`mac_os_x' is not supported!")
    end
  end
end
