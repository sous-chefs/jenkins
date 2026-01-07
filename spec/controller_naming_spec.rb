require 'spec_helper'
require 'yaml'

describe 'controller naming' do
  it 'kitchen.yml uses jenkins.controller attributes' do
    kitchen_path = File.expand_path('../kitchen.yml', __dir__)
    config = YAML.safe_load(File.read(kitchen_path))

    attrs = config.dig('provisioner', 'attributes', 'jenkins')
    expect(attrs).to include('controller')
    expect(attrs).not_to include('master')
  end

  it 'prefers controller attributes for helper endpoint' do
    node = Chef::Node.new
    node.normal['jenkins']['controller']['endpoint'] = 'http://controller.example:8080'

    harness = Class.new do
      include Jenkins::Helper
      attr_reader :node
      def initialize(node)
        @node = node
      end
    end

    expect(harness.new(node).send(:endpoint)).to eq('http://controller.example:8080')
  end
end
