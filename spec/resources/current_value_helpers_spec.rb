require 'spec_helper'

describe 'custom resource current value helpers' do
  platform 'ubuntu'
  step_into :jenkins_agent
  step_into :jenkins_file_credentials
  step_into :jenkins_githubapp_credentials
  step_into :jenkins_jnlp_agent
  step_into :jenkins_password_credentials
  step_into :jenkins_proxy
  step_into :jenkins_secret_text_credentials
  step_into :jenkins_ssh_agent
  step_into :jenkins_view
  step_into :jenkins_windows_agent

  let(:executor) { instance_double(Jenkins::Executor) }

  before do
    allow_any_instance_of(Jenkins::Helper).to receive(:executor)
      .and_return(executor)
    allow(executor).to receive(:groovy).and_return(nil)
    allow(executor).to receive(:groovy!).and_return(nil)
    allow(executor).to receive(:execute!).and_return(true)
  end

  context 'with credential resources' do
    recipe do
      jenkins_password_credentials 'user' do
        id 'password-id'
        password 'secret'
      end

      jenkins_file_credentials 'file.txt' do
        id 'file-id'
        data 'content'
      end

      jenkins_secret_text_credentials 'secret-id' do
        secret 'secret'
      end

      jenkins_githubapp_credentials '12345' do
        id 'github-app-id'
        owner 'sous-chefs'
        private_key_pkcs8_pem 'private-key'
      end
    end

    it 'loads current credentials without action_class visibility errors' do
      expect { chef_run }.not_to raise_error
    end
  end

  context 'with agent resources' do
    recipe do
      jenkins_agent 'agent'

      jenkins_jnlp_agent 'jnlp-agent'

      jenkins_ssh_agent 'ssh-agent' do
        host '127.0.0.1'
      end

      jenkins_windows_agent 'windows-agent'
    end

    it 'loads current agents without action_class visibility errors' do
      expect { chef_run }.not_to raise_error
    end
  end

  context 'with proxy and view resources' do
    recipe do
      jenkins_proxy 'proxy.example.test:8080'

      jenkins_view 'main' do
        jobs %w(build test)
      end
    end

    it 'loads current state without action_class visibility errors' do
      expect { chef_run }.not_to raise_error
    end
  end
end
