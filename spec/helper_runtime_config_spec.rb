require 'spec_helper'

describe Jenkins::Helper do
  let(:node) { Chef::Node.new }

  let(:harness) do
    Class.new do
      include Jenkins::Helper
      attr_reader :node

      def initialize(node)
        @node = node
      end
    end
  end

  it 'prefers runtime config for proxy' do
    node.run_state[:jenkins_runtime_config] = { proxy: 'proxy.example:3128' }
    expect(harness.new(node).send(:proxy)).to eq('proxy.example:3128')
    expect(harness.new(node).send(:proxy_given?)).to eq(true)
  end

  it 'prefers runtime config for endpoint' do
    node.run_state[:jenkins_runtime_config] = { endpoint: 'http://controller.example:8080' }
    expect(harness.new(node).send(:endpoint)).to eq('http://controller.example:8080')
  end

  it 'prefers runtime config for disable_security' do
    node.run_state[:jenkins_runtime_config] = { disable_security: true }
    expect(harness.new(node).send(:security_disabled?)).to eq(true)
  end
end
