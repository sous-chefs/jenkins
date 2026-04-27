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

  it 'defaults the controller home when runtime config is absent' do
    expect(harness.new(node).send(:controller_home)).to eq('/var/lib/jenkins')
  end

  it 'defaults timeout to 120 seconds when runtime config is absent' do
    expect(harness.new(node).send(:timeout)).to eq(120)
  end
end
