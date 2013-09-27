require_relative 'helpers'

describe 'jenkins::_server_package' do
  include Helpers::Jenkins

  # Tests around files
  describe 'files' do
    it 'should install the jenkins package' do
      package('jenkins').must_be_installed
    end

    it 'should create the jenkins template' do
      file(node['jenkins']['server']['config_path']).must_exist.with(
        :owner, 'root').and(
        :group, 'root').and(
        :mode, '0644')
    end
  end

  # Tests around services
  describe 'services' do
    # Make sure the jenkins service is running
    it 'runs the jenkins service' do
      service('jenkins').must_be_running
    end

    # Make sure the jenkins service is enabled on boot
    it 'enables the jenkins service on boot' do
      service('jenkins').must_be_enabled
    end
  end
end
