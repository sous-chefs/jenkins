# copyright: 2018, The Authors

title 'Jenkins Jobs'

control 'jenkins_job-1.0' do
  impact 0.7
  title 'Jenkins Simple Job is created'

  describe jenkins_job('simple-execute') do
    it { should exist }
    its('command') { should eq 'echo "This is Jenkins! Hear me roar!"' }
  end
end

control 'jenkins_job-1.1' do
  impact 0.7
  title 'Jenkins Job with parameters is created'

  describe jenkins_job('execute-with-params') do
    it { should exist }
    its('command') { should eq 'echo "The string param is $STRING_PARAM!" echo "The boolean param is $BOOLEAN_PARAM!"' }
  end

  describe jenkins_build('execute-with-params', 'lastSuccessfulBuild') do
    it { should exist }
    it 'was executed with the correct parameters' do
      expect(subject.parameters).to include(
        'STRING_PARAM' => 'meeseeks',
        'BOOLEAN_PARAM' => true
      )
    end
  end
end

control 'jenkins_job-1.2' do
  impact 0.7
  title 'A folder is created'

  describe jenkins_job('my-folder') do
    it { should exist }
    its('plugin') { should match(/^cloudbees-folder/) }
  end
end

control 'jenkins_job-2.0' do
  impact 0.7
  title 'Jenkins Simple Job is built'

  describe jenkins_build('simple-execute', 'lastSuccessfulBuild') do
    it { should exist }
    it 'was executed with no parameters' do
      expect(subject.parameters).to be_empty
    end
  end
end

control 'jenkins_job-2.1' do
  impact 0.7
  title 'Jenkins Job with parameters is built'

  describe jenkins_build('execute-with-params', 'lastSuccessfulBuild') do
    it { should exist }
    it 'was executed with the correct parameters' do
      expect(subject.parameters).to include(
        'STRING_PARAM' => 'meeseeks',
        'BOOLEAN_PARAM' => true
      )
    end
  end
end

control 'jenkins_job-3.0' do
  impact 0.7
  title 'Jenkins Job is not enabled'

  describe jenkins_job('disable-simple-execute') do
    it { should exist }
    it { should_not be_enabled }
  end
end

control 'jenkins_job-4.0' do
  impact 0.7
  title 'Jenkins Job is enabled'

  describe jenkins_job('enable-simple-execute') do
    it { should exist }
    it { should be_enabled }
  end
end

control 'jenkins_job-5.0' do
  impact 0.7
  title 'Jenkins Job is deleted'

  describe jenkins_job('delete-simple-execute') do
    it { should_not exist }
  end

  describe jenkins_job('non-existent-project') do
    it { should_not exist }
  end
end
