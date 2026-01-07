require 'spec_helper'

describe 'jenkins_plugin custom resource' do
  platform 'ubuntu'
  step_into :jenkins_plugin

  before do
    allow_any_instance_of(Jenkins::Helper).to receive(:executor)
      .and_return(double('executor').as_null_object)

    allow_any_instance_of(Object).to receive(:ensure_update_center_present!)
    allow_any_instance_of(Object).to receive(:plugin_universe).and_return({})
    allow_any_instance_of(Object).to receive(:install_plugin)
    allow(::File).to receive(:exist?).and_call_original
    allow(::File).to receive(:exist?)
      .with('/var/lib/jenkins/plugins/artifactory/META-INF/MANIFEST.MF')
      .and_return(false)
  end

  context 'when installing a plugin' do
    recipe do
      jenkins_plugin 'artifactory'
    end

    it 'converges without raising an error' do
      expect { chef_run }.not_to raise_error
    end
  end
end
