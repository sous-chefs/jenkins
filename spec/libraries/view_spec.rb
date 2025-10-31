require 'spec_helper'

describe 'jenkins_view custom resource' do
  step_into :jenkins_view

  before do
    # Mock the executor to avoid actual Jenkins CLI calls
    allow_any_instance_of(Jenkins::Helper).to receive(:executor)
      .and_return(double('executor').as_null_object)
    
    # Mock the current_view_from_jenkins method to return a view
    allow_any_instance_of(Chef::Resource).to receive(:current_view_from_jenkins)
      .and_return({ jobs: [] })
  end

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
