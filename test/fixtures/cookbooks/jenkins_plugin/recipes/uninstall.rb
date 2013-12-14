include_recipe 'jenkins::server'

# Include the install recipe so we have something to uninstall
include_recipe 'jenkins_plugin::install'

# Grr...
service 'jenkins' do
  action :restart
end

# Jenkins doesn't block after restarting, so we need to wait until the plugins
# are fully installed from the last recipe, with a sensible timeout. 15 seconds
# is entirely arbitrary, but was the lowest number I could go without the test
# failing because Jenkins wasn't ready.
#
# Unrelated comment: Seriously Jenkins, what the actual fuck?
ruby_block 'block_until_plugin_installed' do
  block { sleep(15) }
end

# Test basic job deletion
jenkins_plugin 'greenballs' do
  action :uninstall
end

# Make sure it ignores non-existent jobs
jenkins_plugin 'non-existent-plugin' do
  action :uninstall
end
