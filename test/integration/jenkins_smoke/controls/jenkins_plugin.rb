# copyright: 2018, The Authors

title 'Jenkins Plugins'

control 'jenkins_plugin-1.0' do
  impact 0.7
  title 'jenkins Plugins are installed'

  describe jenkins_plugin('greenballs') do
    it { should exist }
  end

  describe jenkins_plugin('disk-usage') do
    it { should exist }
    its('version') { should eq '0.23' }
  end

  describe jenkins_plugin('copy-to-slave') do
    it { should exist }
    its('version') { should eq '1.4.3' }
  end

  describe jenkins_plugin('nexus-jenkins-plugin') do
    it { should exist }
    its('version') { should eq '3.4.20190116-104331.e820fec' }
  end

  describe jenkins_plugin('github-oauth') do
    it { should exist }
  end

  # Ensure one of github-oauth's deps was installed
  describe jenkins_plugin('github-api') do
    it { should exist }
  end

  # Ensure a transitive dep has been installed
  #
  #   github-oauth -> git -> scm-api
  #
  describe jenkins_plugin('scm-api') do
    it { should exist }
  end

  # Ensure the jquery-ui's deps were not installed
  describe jenkins_plugin('jquery') do
    it { should_not exist }
  end

  describe jenkins_plugin('build-monitor-plugin') do
    it { should exist }
    its('version') { should eq '1.6+build.135' }
  end
end

control 'jenkins_plugin-2.0' do
  impact 0.7
  title 'jenkins Plugins are disabled'

  describe jenkins_plugin('ansicolor') do
    it { should exist }
    it { should_not be_enabled }
  end
end

control 'jenkins_plugin-3.0' do
  impact 0.7
  title 'jenkins Plugins are enabled'

  describe jenkins_plugin('jira-trigger') do
    it { should exist }
    it { should be_enabled }
  end
end

control 'jenkins_plugin-4.0' do
  impact 0.7
  title 'jenkins Plugins are uninstalled'

  describe jenkins_plugin('confluence-publisher') do
    it { should_not exist }
  end

  describe jenkins_plugin('non-existent-plugin') do
    it { should_not exist }
  end
end
