require 'spec_helper'

describe 'jenkins_executor_config custom resource' do
  platform 'ubuntu'
  step_into :jenkins_executor_config

  context 'when configuring runtime settings' do
    recipe do
      jenkins_executor_config 'default' do
        endpoint 'http://controller.example:8080'
        proxy 'proxy.example:3128'
        disable_security true
      end
    end

    it 'populates node.run_state[:jenkins_runtime_config]' do
      chef_run

      expect(chef_run.node.run_state[:jenkins_runtime_config]).to eq(
        endpoint: 'http://controller.example:8080',
        proxy: 'proxy.example:3128',
        disable_security: true
      )
    end
  end
end
