require 'serverspec'
include Serverspec::Helper::Exec
include Serverspec::Helper::DetectOS

# Require support files
Dir[File.expand_path('../support/**/*.rb', __FILE__)].each { |file| require_relative(file) }

RSpec.configure do |config|
  config.before(:all) do
    config.os = backend(Serverspec::Commands::Base).check_os
  end
end
