require_relative 'helpers'

describe 'jenkins::_node_jnlp' do
  include Helpers::Jenkins

  # Tests around users and groups
  describe 'users and groups' do
    it 'should create the jenkins node group' do
      group(node['jenkins']['node']['user']).must_exist
    end

    it 'should create the jenkins node user' do
      user(node['jenkins']['node']['user']).must_exist.with(
        :home, node['jenkins']['node']['home'])
    end
  end

  # Tests around files
  describe 'files' do
    it 'should grab the jenkins slave JAR' do
      slave_jar = "#{node['jenkins']['node']['home']}/slave.jar"

      file(slave_jar).must_exist.with(
        :owner, node['jenkins']['node']['user'])
    end

    it 'should create the run file for the jenkins-slave runit service' do
      file('/etc/sv/jenkins-slave/run').must_exist
    end

    it 'should make sure the run script is executable for jenkins-slave runit' do
      assert_sh('file /etc/sv/jenkins-slave/run | grep executable')
    end
  end

  # Tests around directories
  describe 'directories' do
    it 'should create the jenkins home directory' do
      directory(node['jenkins']['node']['home']).must_exist.with(
      :owner, node['jenkins']['node']['user']).and(
      :group, node['jenkins']['node']['user'])
    end
  end

  # Tests around services
  describe 'services' do
    # Make sure the jenkins-slave service is running
    it 'runs the jenkins-slave service' do
      service('jenkins-slave').must_be_running
    end

    # Make sure the jenkins-slave service is enabled on boot
    # NOTE: runit does not use the normal channels to start things on bootup
    #       runit uses a 'service directory' to guide its usage (/etc/sv/<service>)
    #
    #       So, we will just check to make sure that the service directory was
    #       created for jenkins-slave, and that the symbolic links were set up correctly.
  end

  # Other tests
  describe 'other' do
    # Make sure the slave is listed as a node for the jenkins server
    it 'should be listed as a node for the jenkins server' do
      auth = "-i #{node['jenkins']['node']['ssh_private_key']}" if node['jenkins']['node']['ssh_private_key']
      assert_sh("java -jar #{node['jenkins']['node']['home']}/jenkins-cli.jar #{auth} -s #{node['jenkins']['server']['url']} get-node #{node['jenkins']['node']['name']}")
    end
  end
end
