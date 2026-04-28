require 'spec_helper'
require 'yaml'

describe 'runtime configuration migration' do
  it 'kitchen.yml no longer injects jenkins node attributes' do
    kitchen_path = File.expand_path('../kitchen.yml', __dir__)
    config = YAML.safe_load(File.read(kitchen_path), aliases: true)

    expect(config.dig('provisioner', 'attributes')).to be_nil
  end

  it 'defaults the helper endpoint without legacy controller attributes' do
    node = Chef::Node.new

    harness = Class.new do
      include Jenkins::Helper
      attr_reader :node

      def initialize(node)
        @node = node
      end
    end

    expect(harness.new(node).send(:endpoint)).to eq('http://localhost:8080')
  end
end
