# copyright: 2018, The Authors

title 'Jenkins Slaves'

# Note:
# Testing that slaves are connected and/or online is prone to failure
# due to slow performance, different virtualization, etc

control 'jenkins_slave-1.0' do
  impact 0.7
  title 'Jenkins JNLP Slaves are created and configured'

  #
  # JNLP Slave #1
  # ------------------------------
  describe jenkins_slave('jnlp-builder') do
    it { should exist }
    its('description') { should eq 'A generic slave builder' }
    its('remote_fs') { should eq '/tmp/jenkins/slaves/builder' }
    its('labels') { should eq %w(builder linux) }
    it { should be_connected }
    it { should be_online }
  end

  describe group('jenkins-builder') do
    it { should exist }
  end

  describe user('jenkins-builder') do
    it { should exist }
    its('groups') { should include('jenkins-builder') }
  end

  describe file('/tmp/jenkins/slaves/builder') do
    it { should be_directory }
  end

  describe.one do
    describe service('jenkins-slave-builder') do
      it { should be_running }
    end

    describe runit_service('jenkins-slave-builder') do
      it { should be_running }
    end
  end

  #
  # JNLP Slave #2
  # ------------------------------
  describe jenkins_slave('jnlp-smoke') do
    it { should exist }
    its('description') { should eq 'Run high-level integration tests' }
    its('remote_fs') { should eq '/tmp/jenkins/slaves/smoke' }
    its('usage_mode') { should eq 'exclusive' }
    its('availability') { should eq 'Demand' }
    its('in_demand_delay') { should eq 1 }
    its('idle_delay') { should eq 3 }
    its('labels') { should eq %w(fast runner) }

    # it might be connected, depending on disconnection timing
    # it { should be_connected }
    it { should be_online }
  end

  describe group('jenkins-smoke') do
    it { should exist }
  end

  describe user('jenkins-smoke') do
    it { should exist }
    its('groups') { should include('jenkins-smoke') }
  end

  describe file('/tmp/jenkins/slaves/smoke') do
    it { should be_directory }
  end

  describe.one do
    describe service('jenkins-slave-smoke') do
      it { should be_running }
    end

    describe runit_service('jenkins-slave-smoke') do
      it { should be_running }
    end
  end

  #
  # JNLP Slave #3
  # ------------------------------
  describe jenkins_slave('jnlp-executor') do
    it { should exist }
    its('description') { should eq 'Run test suites' }
    its('remote_fs') { should eq '/tmp/jenkins/slaves/executor' }
    its('labels') { should eq %w(executor freebsd jail) }
    its('environment') { should include('FOO' => 'bar', 'BAZ' => 'qux') }
    it { should be_connected }
    it { should be_online }
  end

  describe group('jenkins-executor') do
    it { should exist }
  end

  describe user('jenkins-executor') do
    it { should exist }
    its('groups') { should include('jenkins-executor') }
  end

  describe file('/tmp/jenkins/slaves/executor') do
    it { should be_directory }
  end

  describe.one do
    describe service('jenkins-slave-executor') do
      it { should be_running }
    end

    describe runit_service('jenkins-slave-executor') do
      it { should be_running }
    end
  end
end

control 'jenkins_slave-2.0' do
  impact 0.7
  title 'Jenkins SSH Slaves are created and configured'

  #
  # SSH Slave #1
  # ------------------------------
  describe jenkins_slave('ssh-builder') do
    it { should exist }
    its('description') { should eq 'A builder, but over SSH' }
    its('remote_fs') { should eq '/tmp/slave-ssh-builder' }
    its('labels') { should eq %w(builder linux) }
    its('host') { should eq 'localhost' }
    its('port') { should eq 22 }
    its('credentials_id') { should eq '38537014-ec66-49b5-aff2-aed1c19e2989' }
    its('credentials_username') { should eq 'jenkins-ssh-key' }
    its('java_path') { should eq '/usr/bin/java' }
    its('launch_timeout') { should eq 120 }
    its('ssh_retries') { should eq 5 }
    its('ssh_wait_retries') { should eq 60 }
    it { should be_connected }
    it { should be_online }
  end

  #
  # SSH Slave #2
  # ------------------------------
  describe jenkins_slave('ssh-executor') do
    it { should exist }
    its('description') { should eq 'An executor, but over SSH' }
    its('remote_fs') { should eq '/tmp/slave-ssh-executor' }
    its('labels') { should eq %w(executor freebsd jail) }
    its('host') { should eq 'localhost' }
    its('port') { should eq 22 }
    its('credentials_id') { should eq '38537014-ec66-49b5-aff2-aed1c19e2989' }
    its('credentials_username') { should eq 'jenkins-ssh-key' }
    its('launch_timeout') { should eq 120 }
    its('ssh_retries') { should eq 5 }
    its('ssh_wait_retries') { should eq 60 }
    it { should be_connected }
    it { should be_online }
  end

  #
  # SSH Slave #3
  # ------------------------------
  describe jenkins_slave('ssh-smoke') do
    it { should exist }
    its('description') { should eq 'A smoke tester, but over SSH' }
    its('remote_fs') { should eq '/home/jenkins-ssh-password' }
    its('labels') { should eq %w(fast runner) }
    its('host') { should eq 'localhost' }
    its('port') { should eq 22 }
    its('credentials_id') { should eq 'jenkins-ssh-password' }
    its('credentials_username') { should eq 'jenkins-ssh-password' }
    its('launch_timeout') { should eq 120 }
    its('ssh_retries') { should eq 5 }
    its('ssh_wait_retries') { should eq 60 }
    it { should be_connected }
    it { should be_online }
  end
end

control 'jenkins_slave-3.0' do
  impact 0.7
  title 'Jenkins SSH Slave is connected'

  describe jenkins_slave('ssh-to-connect') do
    it { should exist }
    it { should be_connected }
  end
end

control 'jenkins_slave-4.0' do
  impact 0.7
  title 'Jenkins SSH Slave is online'

  describe jenkins_slave('ssh-to-online') do
    it { should exist }
    it { should be_connected }
    it { should be_online }
  end
end

control 'jenkins_slave-5.0' do
  impact 0.7
  title 'Jenkins SSH Slave is offline'

  describe jenkins_slave('ssh-to-offline') do
    it { should exist }
    it { should_not be_online }
    its('offline_reason') { should eq 'Autobots ran out of energy' }
  end
end

control 'jenkins_slave-6.0' do
  impact 0.7
  title 'Jenkins SSH Slave is disconnected'

  describe jenkins_slave('ssh-to-disconnect') do
    it { should exist }
    it { should_not be_connected }
  end
end

control 'jenkins_slave-7.0' do
  impact 0.7
  title 'Jenkins JNLP Slave is deleted'

  describe jenkins_slave('jnlp-to-delete') do
    it { should_not exist }
  end

  describe jenkins_slave('jnlp-missing') do
    it { should_not exist }
  end
end

control 'jenkins_slave-8.0' do
  impact 0.7
  title 'Jenkins SSH Slave is deleted'

  describe jenkins_slave('ssh-to-delete') do
    it { should_not exist }
  end

  describe jenkins_slave('ssh-missing') do
    it { should_not exist }
  end
end
