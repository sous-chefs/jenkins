require 'spec_helper'

RSpec.describe Chef::Provider::JenkinsView do
  describe 'provides :jenkins_view' do
    before do
      allow(described_class).to receive(:new).and_wrap_original do |m, *args|
        view_double = double('view').tap do |d|
          allow(d).to receive(:[]).with(:jobs).and_return([])
        end
        m.call(*args).tap do |v|
          allow(v).to receive(:current_view).and_return(view_double)
          allow(v).to receive(:executor)
            .and_return(double('executor').as_null_object)
        end
      end
    end

    step_into :jenkins_view

    recipe do
      jenkins_view 'ham' do
        jobs %w(pig giraffe)
      end
    end

    it 'should not raise Chef::Exceptions::ProviderNotFound' do
      expect { chef_run }.not_to raise_error
    end
  end
end
