require 'spec_helper'

describe jenkins_job('simple-execute') do
  it { should be_a_jenkins_job }
  it { should have_command('echo "This is Jenkins! Hear me roar!"') }
end

describe jenkins_build('simple-execute', 'lastSuccessfulBuild') do
  it { should exist }
  it 'was executed with no parameters' do
    expect(subject.parameters).to be_empty
  end
end

describe jenkins_job('execute-with-params') do
  it { should be_a_jenkins_job }
  it { should have_command('echo "The string param is $STRING_PARAM!" echo "The boolean param is $BOOLEAN_PARAM!"') }
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
