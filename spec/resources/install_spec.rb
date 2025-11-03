require 'spec_helper'

describe 'jenkins_install' do
  platform 'ubuntu', '20.04'
  step_into :jenkins_install

  context 'when installing via war method' do
    context 'with default system account settings' do
      recipe do
        node.normal['jenkins']['java'] = '/usr/bin/java'
        
        jenkins_install 'default' do
          install_method 'war'
          home '/opt/bacon'
          log_directory '/opt/bacon/log'
          user 'bacon'
          group 'meats'
        end
      end

      it 'creates the user' do
        expect(chef_run).to create_user('bacon')
          .with_home('/opt/bacon')
      end

      it 'creates the group' do
        expect(chef_run).to create_group('meats')
          .with_members(['bacon'])
      end

      it 'creates the home directory' do
        expect(chef_run).to create_directory('/opt/bacon')
          .with_owner('bacon')
          .with_group('meats')
          .with_mode('0755')
          .with_recursive(true)
      end

      it 'creates the log directory' do
        expect(chef_run).to create_directory('/opt/bacon/log')
          .with_owner('bacon')
          .with_group('meats')
          .with_mode('0755')
          .with_recursive(true)
      end

      it 'downloads the jenkins war file' do
        expect(chef_run).to create_remote_file('/opt/bacon/jenkins.war')
      end

      it 'creates systemd unit' do
        expect(chef_run).to create_systemd_unit('jenkins.service')
      end

      it 'enables and starts jenkins service' do
        expect(chef_run).to enable_service('jenkins')
        expect(chef_run).to start_service('jenkins')
      end
    end

    context 'with system account enabled' do
      recipe do
        node.normal['jenkins']['java'] = '/usr/bin/java'
        
        jenkins_install 'default' do
          install_method 'war'
          home '/opt/bacon'
          log_directory '/opt/bacon/log'
          user 'bacon'
          group 'meats'
          use_system_accounts true
        end
      end

      it 'creates the user as system account' do
        expect(chef_run).to create_user('bacon')
          .with_home('/opt/bacon')
          .with(system: true)
      end

      it 'creates the group as system account' do
        expect(chef_run).to create_group('meats')
          .with_members(['bacon'])
          .with(system: true)
      end
    end
  end

  context 'when installing via package method on debian' do
    platform 'ubuntu', '20.04'

    recipe do
      node.normal['jenkins']['java'] = '/usr/bin/java'
      
      jenkins_install 'default' do
        install_method 'package'
      end
    end

    it 'installs required packages' do
      expect(chef_run).to install_package(%w(apt-transport-https fontconfig))
    end

    it 'adds apt repository' do
      expect(chef_run).to add_apt_repository('jenkins-ci-stable')
    end

    it 'configures dpkg autostart' do
      # dpkg_autostart resource exists in the run
      expect(chef_run.find_resource(:dpkg_autostart, 'jenkins')).to_not be_nil
    end

    it 'installs jenkins package' do
      expect(chef_run).to install_package('jenkins')
    end

    it 'creates the home directory' do
      expect(chef_run).to create_directory('/var/lib/jenkins')
        .with_owner('jenkins')
        .with_group('jenkins')
        .with_mode('0755')
    end

    it 'creates the log directory' do
      expect(chef_run).to create_directory('/var/log/jenkins')
        .with_owner('jenkins')
        .with_group('jenkins')
        .with_mode('0755')
        .with_recursive(true)
    end

    it 'creates supplemental directories' do
      %w(cache lib run).each do |folder|
        expect(chef_run).to create_directory("fix permissions for /var/#{folder}/jenkins")
          .with_path("/var/#{folder}/jenkins")
          .with_owner('jenkins')
          .with_group('jenkins')
      end
    end

    it 'creates debian config file' do
      expect(chef_run).to create_template('/etc/default/jenkins')
        .with_source('jenkins-config-debian.erb')
        .with_mode('0644')
    end

    it 'creates init.groovy.d directory' do
      expect(chef_run).to create_directory('/var/lib/jenkins/init.groovy.d')
        .with_owner('jenkins')
        .with_group('jenkins')
        .with_mode('0755')
    end

    it 'creates anonymous read groovy script' do
      expect(chef_run).to create_file('/var/lib/jenkins/init.groovy.d/grant-anonymous-read.groovy')
        .with_owner('jenkins')
        .with_group('jenkins')
        .with_mode('0644')
    end

    it 'enables and starts jenkins service' do
      expect(chef_run).to enable_service('jenkins')
      expect(chef_run).to start_service('jenkins')
    end
  end

  # RHEL tests skipped due to yum-epel dependency complexity in ChefSpec
  # Integration tests cover RHEL package installation
end
