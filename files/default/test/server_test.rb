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
          :group, node['jenkins']['server']['plugins_dir_group'])
      end
    end

    it 'configures ssl properly if configured to' do
      if node['jenkins']['http_proxy']['ssl']['enabled']
        case node['jenkins']['http_proxy']['variant']
        when 'apache'
          file(File.join(node['apache']['dir'], 'sites-available/jenkins')).must_include(
            "SSLCertificateFile #{node['jenkins']['http_proxy']['ssl']['cert_path']}")
          file(File.join(node['apache']['dir'], 'sites-available/jenkins')).must_include(
            "SSLCertificateKeyFile #{node['jenkins']['http_proxy']['ssl']['key_path']}")
          if node['jenkins']['http_proxy']['ca_cert_path']
            file(File.join(node['apache']['dir'], 'sites-available/jenkins')).must_include(
              "SSLCACertificateFile #{node['jenkins']['http_proxy']['ssl']['ca_cert_path']}")
          end
        when 'nginx'
          file(File.join(node['nginx']['dir'], 'sites-available/jenkins.conf')).must_include(
            "ssl_certificate     #{node['jenkins']['http_proxy']['ssl']['cert_path']}")
          file(File.join(node['nginx']['dir'], 'sites-available/jenkins.conf')).must_include(
            "ssl_certificate_key #{node['jenkins']['http_proxy']['ssl']['key_path']}")
        end
      end
    end
  end

  # Tests around directories
  describe 'directories' do
    it 'should create the jenkins home, log, plugins and ssh directories' do
      home_dir = node['jenkins']['server']['home']
      plugins_dir = File.join(home_dir, 'plugins')
      log_dir = node['jenkins']['server']['log_dir']
      ssh_dir = File.join(home_dir, '.ssh')

      directory(home_dir).must_exist.with(
          :owner, node['jenkins']['server']['user']).and(
          :group, node['jenkins']['server']['home_dir_group']).and(
          :mode, node['jenkins']['server']['dir_permissions'])

      directory(plugins_dir).must_exist.with(
          :owner, node['jenkins']['server']['user']).and(
          :group, node['jenkins']['server']['plugins_dir_group']).and(
          :mode, node['jenkins']['server']['dir_permissions'])

      directory(log_dir).must_exist.with(
          :owner, node['jenkins']['server']['user']).and(
          :group, node['jenkins']['server']['log_dir_group']).and(
          :mode, node['jenkins']['server']['log_dir_permissions'])

      directory(ssh_dir).must_exist.with(
          :owner, node['jenkins']['server']['user']).and(
          :group, node['jenkins']['server']['ssh_dir_group']).and(
          :mode, node['jenkins']['server']['ssh_dir_permissions'])
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
