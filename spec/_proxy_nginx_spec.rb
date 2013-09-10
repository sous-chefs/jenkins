require 'spec_helper'

describe 'jenkins::_proxy_nginx' do
  before do
    # Stupid resource cloning
    Chef::Log.stub(:warn)
  end

  let(:chef_run) do
    ChefSpec::ChefRunner.new(platform: 'ubuntu', version: '12.04').converge('jenkins::_proxy_nginx')
  end

  it 'installs nginx' do
    expect(chef_run).to include_recipe('nginx::default')
  end

  context '/etc/nginx/htpasswd' do
    let(:template) { chef_run.template('/etc/nginx/htpasswd') }

    it 'creates the template' do
      expect(chef_run).to create_file('/etc/nginx/htpasswd')
    end

    it 'is owned by www-data:www-data' do
      expect(template.owner).to eq('www-data')
      expect(template.group).to eq('www-data')
    end

    it 'has 0600 permissions' do
      expect(template.mode).to eq('0600')
    end
  end

  context '/etc/nginx/sites-available/jenkins.conf' do
    let(:template) { chef_run.template('/etc/nginx/sites-available/jenkins.conf') }

    it 'creates the template' do
      expect(chef_run).to create_file('/etc/nginx/sites-available/jenkins.conf')
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
