require_relative '../../../kitchen/data/spec_helper'

# Make sure the pid set before installing the plugin has not changed.
describe file("/tmp/kitchen/cache/install_no_restart.pid") do
  it { should contain `pgrep -f /usr/lib/jenkins/jenkins.war`.strip }
end

describe jenkins_plugin('disk-usage') do
  it { should be_a_jenkins_plugin }
end
