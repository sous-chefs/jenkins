require_relative 'helpers'

describe 'jenkins::server' do
  include Helpers::Jenkins

  # Tests around users and groups
  describe 'users and groups' do
    # Check if the jenkins user was created with the correct home path
    it 'should create the jenkins user with the correct home path' do
      user('jenkins').must_exist.with(:home, node['jenkins']['server']['home'])
    end
  end

  # Tests around files
  describe 'files' do
    it 'should install the plugins it is told to' do
      home_dir = node['jenkins']['server']['home']
      plugins_dir = File.join(home_dir, 'plugins')

      node['jenkins']['server']['plugins'].each do |plugin|
        # Handle grabbing the correct plugin name
        if plugin.is_a?(Hash)
          name = plugin['name']
        else
          name = plugin
        end

        file(File.join(plugins_dir, "#{name}.jpi")).must_exist.with(
          :owner, node['jenkins']['server']['user']).and(
          :group, node['jenkins']['server']['group'])
      end
    end
  end

  # Tests around directories
  describe 'directories' do
    # NOTE: We check the home_dir and log_dir in respective install method tests.
    #       This is because the directory owner changes based on installation method.
    it 'should create the jenkins plugins and ssh directories' do
      home_dir = node['jenkins']['server']['home']
      plugins_dir = File.join(home_dir, 'plugins')
      ssh_dir = File.join(home_dir, '.ssh')

      [plugins_dir, ssh_dir].each do |dir_name|
        directory(dir_name).must_exist.with(
          :owner, node['jenkins']['server']['user']).and(
          :group, node['jenkins']['server']['group']).and(
          :mode, '0700')
      end
    end
  end

  # Tests around services
  describe 'services' do
    # Make sure the jenkins service is running
    it 'runs the jenkins service' do
      service('jenkins').must_be_running
    end
  end

  # Tests around networking
  describe 'networking' do
    # Make sure the machine is listening on the jenkins server port
    it 'listens on the jenkins server port' do
      assert_sh("netstat -lnt | grep :#{node['jenkins']['server']['port']}")
    end
  end
end
