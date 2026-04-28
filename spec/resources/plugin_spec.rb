require 'spec_helper'

describe 'jenkins_plugin custom resource' do
  platform 'ubuntu'
  step_into :jenkins_plugin
  let(:executor) { instance_double(Jenkins::Executor, execute!: true) }

  before do
    allow_any_instance_of(Jenkins::Helper).to receive(:executor)
      .and_return(executor)

    allow_any_instance_of(Jenkins::Helper).to receive(:ensure_update_center_present!)
    allow_any_instance_of(Jenkins::Helper).to receive(:plugin_universe).and_return({})
    allow(::File).to receive(:exist?).and_call_original
    allow(::File).to receive(:exist?)
      .with('/var/lib/jenkins/plugins/artifactory/META-INF/MANIFEST.MF')
      .and_return(false)
  end

  context 'when installing a plugin' do
    recipe do
      jenkins_plugin 'artifactory'
    end

    it 'invokes the authenticated cli path for update-center installs' do
      chef_run

      expect(executor).to have_received(:execute!).with('install-plugin', 'artifactory', nil)
    end
  end
end
