require 'spec_helper'

describe 'jenkins::java' do
  context 'on Debian' do
    cached(:chef_run) do
      ChefSpec::SoloRunner.new(platform: 'debian', version: '8.9')
                          .converge(described_recipe)
    end

    it 'installs openjdk-7-jdk' do
      expect(chef_run).to install_package('openjdk-7-jdk')
    end
  end

  context 'on Ubuntu 14.04' do
    cached(:chef_run) do
      ChefSpec::SoloRunner.new(platform: 'ubuntu', version: '14.04')
                          .converge(described_recipe)
    end

    it 'installs openjdk-7-jdk' do
      expect(chef_run).to install_package('openjdk-7-jdk')
    end
  end

  context 'on Ubuntu 16.04' do
    cached(:chef_run) do
      ChefSpec::SoloRunner.new(platform: 'ubuntu', version: '16.04')
                          .converge(described_recipe)
    end

    it 'installs openjdk-8-jdk' do
      expect(chef_run).to install_package('openjdk-8-jdk')
    end
  end

  context 'on CentOS 7' do
    cached(:chef_run) do
      ChefSpec::SoloRunner.new(platform: 'centos', version: '7.3.1611')
                          .converge(described_recipe)
    end

    it 'installs java-1.8.0-openjdk' do
      expect(chef_run).to install_package('java-1.8.0-openjdk')
    end
  end

  context 'on Amazon Linux 2017.03' do
    cached(:chef_run) do
      ChefSpec::SoloRunner.new(platform: 'amazon', version: '2017.03')
                          .converge(described_recipe)
    end

    it 'installs java-1.8.0-openjdk' do
      expect(chef_run).to install_package('java-1.8.0-openjdk')
    end
  end

  context 'on an unsupported platform' do
    cached(:chef_run) do
      ChefSpec::SoloRunner.new(platform: 'mac_os_x', version: '10.12')
                          .converge(described_recipe)
    end

    it 'raises an exception' do
      expect { chef_run }
        .to raise_error(RuntimeError, "`mac_os_x' is not supported!")
    end
  end
end
