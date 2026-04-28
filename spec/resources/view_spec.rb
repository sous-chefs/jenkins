require 'spec_helper'

describe 'jenkins_view custom resource' do
  platform 'ubuntu'
  step_into :jenkins_view
  let(:executor) { instance_double(Jenkins::Executor) }

  before do
    # Mock the executor to avoid actual Jenkins CLI calls
    allow_any_instance_of(Jenkins::Helper).to receive(:executor)
      .and_return(executor)
    allow(executor).to receive(:groovy!).and_return('{"jobs":[]}', nil)
  end

  context 'when creating a view' do
    recipe do
      jenkins_view 'ham' do
        jobs %w(pig giraffe)
      end
    end

    it 'creates a jenkins view without raising an error' do
      expect { chef_run }.not_to raise_error
    end

    it 'converges successfully' do
      expect(chef_run).to create_jenkins_view('ham').with(jobs: %w(pig giraffe))
    end
  end
end
