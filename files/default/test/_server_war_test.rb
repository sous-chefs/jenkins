require_relative 'helpers'

describe 'jenkins::_server_war' do
  include Helpers::Jenkins

  # Tests around files
  describe 'files' do
    it 'should grab the jenkins.war file' do
      home_dir = node['jenkins']['server']['home']

      file(File.join(home_dir, 'jenkins.war')).must_exist.with(
        :owner, node['jenkins']['server']['user']).and(
        :group, node['jenkins']['server']['home_dir_group'])
    end

    it 'should create the run file for the jenkins runit service' do
      file('/etc/sv/jenkins/run').must_exist
    end

    it 'should make sure the run script is executable for jenkins runit' do
      assert_sh('file /etc/sv/jenkins/run | grep executable')
    end
  end

  # Tests around services
  describe 'services' do
    # Make sure the jenkins service is running
    it 'runs the jenkins service' do
      service('jenkins').must_be_running
    end

    # Make sure the jenkins-slave service is enabled on boot
    # NOTE: runit does not use the normal channels to start things on bootup
    #       runit uses a 'service directory' to guide its usage (/etc/sv/<service>)
    #
    #       So, we will just check to make sure that the service directory was
    #       created for jenkins-slave, and that the symbolic links were set up correctly.
  end
end
