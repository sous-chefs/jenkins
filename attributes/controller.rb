#
# Cookbook:: jenkins
# Attributes:: master
#
# Author: Doug MacEachern <dougm@vmware.com>
# Author: Fletcher Nichol <fnichol@nichol.ca>
# Author: Seth Chisamore <schisamo@chef.io>
# Author: Seth Vargo <sethvargo@gmail.com>
#
# Copyright:: 2010-2016, VMware, Inc.
# Copyright:: 2012-2019, Chef Software, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

default['jenkins']['master'].tap do |master|
  #
  # Jenkins user/group should be created as `system` accounts for `war` install.
  # The default of `true` will ensure that **new** jenkins user accounts are
  # created in the system ID range, existing users will not be modified.
  # Used by jnlp_agent resource.
  #
  #   node.normal['jenkins']['master']['use_system_accounts'] = false
  #
  master['use_system_accounts'] = true

  #
  # The host the Jenkins master is running on. For single-installs, the default
  # value of +localhost+ will suffice. For multi-node installs, you will likely
  # need to update this attribute to the FQDN of your Jenkins master.
  #
  # If you are running behind a proxy, please see the documentation for the
  # +endpoint+ attribute instead.
  #
  master['host'] = 'localhost'

  #
  # The port which the Jenkins process will listen on.
  # Used to construct the endpoint URL.
  #
  master['port'] = 8080

  #
  # The top-level endpoint for the Jenkins master. By default, this is a
  # "compiled" attribute from +jenkins.master.host+ and +jenkins.master.port+,
  # but you will need to change this attribute if you choose to serve Jenkins
  # behind an HTTP(s) proxy. For example, if you have an Nginx proxy that runs
  # Jenkins on port 80 on a custom domain with a proxy, you will need to set
  # that attribute here:
  #
  #   node.normal['jenkins']['master']['endpoint'] = 'https://custom.domain.com/jenkins'
  #
  master['endpoint'] = "http://#{node['jenkins']['master']['host']}:#{node['jenkins']['master']['port']}"

  #
  # The path to the Jenkins home location. This will also become the value of
  # +$JENKINS_HOME+. Used by plugin resource and helper library.
  #
  master['home'] = '/var/lib/jenkins'

  # Allow tests and certain environments to disable Jenkins security entirely.
  # Defaults to false so normal installs remain secured.
  # Used by helper library.
  master['disable_security'] = false

  #
  # Sleep time in seconds to allow the update center data to quiesce in Jenkins.
  # This is so that we don't run into issues with plugin installations which can
  # happen depending on system load. Used by helper library.
  #
  master['update_center_sleep'] = 5

  #
  # The mirror to download update center data from.
  # Used by helper library for plugin installation.
  #
  master['mirror'] = 'https://updates.jenkins.io'

  #
  # The "channel" to use for update center, default is stable.
  # Used by helper library for plugin installation.
  #
  master['channel'] = 'stable'
end
