require 'chefspec'
require 'chefspec/berkshelf'

# Require all our libraries
Dir['libraries/*.rb'].each { |f| require File.expand_path(f) }

RSpec.configure do |config|
  config.log_level = :fatal

  # Use color in STDOUT
  config.color = true

  # Guard against people using deprecated RSpec syntax
  config.raise_errors_for_deprecations!

  # Use the specified formatter
  config.formatter = :documentation

  # Why aren't these the defaults?
  config.filter_run focus: true
  config.run_all_when_everything_filtered = true

  # Set a default platform (this is overriden as needed)
  config.platform  = 'ubuntu'
  config.version   = '14.04'

  # Be random!
  config.order = 'random'
end
