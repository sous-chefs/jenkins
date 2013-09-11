require 'spec_helper'

describe 'jenkins::_proxy_apache2' do
  before do
    # Stupid resource cloning
    Chef::Log.stub(:warn)
  end

  let(:chef_run) do
    ChefSpec::ChefRunner.new(platform: 'ubuntu', version: '12.04').converge('jenkins::_proxy_apache2')
  end

  it 'installs apache2' do
    expect(chef_run).to include_recipe('apache2::default')
  end

  context "when node['jenkins']['http_proxy']['ssl']['enabled'] is true" do
    let(:chef_run) do
      ChefSpec::ChefRunner.new(platform: 'ubuntu', version: '12.04') do |node|
        node.set['jenkins']['http_proxy']['ssl']['enabled'] = true
      end.converge('jenkins::_proxy_apache2')
    end

    it 'installs apache::mod_ssl' do
      expect(chef_run).to include_recipe('apache2::mod_ssl')
    end
  end

  context '/etc/apache2/htpasswd' do
    let(:template) { chef_run.template('/etc/apache2/htpasswd') }

    it 'creates the template' do
      expect(chef_run).to create_file('/etc/apache2/htpasswd')
    end

    it 'is owned by www-data:www-data' do
      expect(template.owner).to eq('www-data')
      expect(template.group).to eq('www-data')
    end

    it 'has 0600 permissions' do
      expect(template.mode).to eq('0600')
    end
  end

  context '/etc/apache2/sites-available/jenkins' do
    let(:template) { chef_run.template('/etc/apache2/sites-available/jenkins') }

    it 'creates the template' do
      expect(chef_run).to create_file('/etc/apache2/sites-available/jenkins')
    end

    it 'is owned by root:root' do
      expect(template.owner).to eq('root')
      expect(template.group).to eq('root')
    end

    it 'has 0644 permissions' do
      expect(template.mode).to eq('0644')
    end
  end
end
