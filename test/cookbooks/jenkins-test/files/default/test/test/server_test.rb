require_relative 'helpers'


describe 'jenkins_test::server' do

  # Include helpers
  include Helpers::Jenkins_test

  # Tests around users and groups
  describe "users and groups" do

    # Check if the jenkins user was created with the correct home path
    it "should create the jenkins user with the correct home path" do
      user("jenkins").must_exist.with(:home, node['jenkins']['server']['home'])
    end

  end

  # Tests around files
  describe "files" do

    it "should install the plugins it is told to" do
      plugins_dir = File.join(node['jenkins']['server']['data_dir'], "plugins")

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

    it "should grab the jenkins.war file" do
      home_dir = node['jenkins']['server']['home']

      file(File.join(home_dir, "jenkins.war")).must_exist.with(
        :owner, node['jenkins']['server']['user']).and(
        :group, node['jenkins']['server']['group'])
    end

    it "should create the run file for the jenkins runit service" do
      file("/etc/sv/jenkins/run").must_exist
    end

    it "should make sure the run script is executable for jenkins runit" do
      assert_sh("file /etc/sv/jenkins/run | grep executable")
    end

  end

  # Tests around directories
  describe "directories" do

    it "should create the necessary directories" do
      home_dir = node['jenkins']['server']['home']
      data_dir = node['jenkins']['server']['data_dir']
      plugins_dir = File.join(node['jenkins']['server']['data_dir'], "plugins")
      log_dir = node['jenkins']['server']['log_dir']
      ssh_dir = File.join(home_dir, ".ssh")

      # Loop over the created directories and check them
      [home_dir, data_dir, plugins_dir, log_dir, ssh_dir].each do |dir_name|
        directory(dir_name).must_exist.with(
          :owner, node['jenkins']['server']['user']).and(
          :group, node['jenkins']['server']['group']).and(
          :mode, '0700')
      end
    end

    it "should create the jenkins service directory for runit" do
      directory("/etc/sv/jenkins").must_exist
    end

  end

  # Tests around services
  describe "services" do

    # Make sure the jenkins service is running
    it "runs the jenkins service" do
      service("jenkins").must_be_running
    end

    # Make sure the jenkins service is enabled on boot
    # NOTE: runit does not use the normal channels to start things on bootup
    #       runit uses a "service directory" to guide its usage (/etc/sv/<service>)
    #
    #       So, we will just check to make sure that the service directory was
    #       created for jenkins correctly.

  end

  # Tests around networking
  describe "networking" do

    # Make sure the machine is listening on the jenkins server port
    it "listens on the jenkins server port" do
      assert_sh("netstat -lnt | grep :#{node['jenkins']['server']['port']}")
    end

  end

end