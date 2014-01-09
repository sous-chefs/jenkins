#
# Cookbook Name:: jenkins
# Attributes:: executor
#
# Author: Seth Vargo <sethvargo@getchef.com>
#
# Copyright 2013-2014, Chef Software, Inc.
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

default['jenkins']['executor'].tap do |executor|
  #
  # This is the number of seconds to wait for Jenkins to become "ready" after a
  # start, restart, or reload. Since the Jenkins service returns immediately
  # and the actual Java process is started in the background, we block the Chef
  # Client run until the service endpoint(s) are _actually_ ready to accept
  # requests.
  #
  executor['timeout'] = 60

  #
  # If your Jenkins master requires authentication, you must set the private
  # key.
  #
  # For example, you could load this private key via a search:
  #
  #   master = search(:node, 'fqdn: master.ci.example.com')
  #   node.set['jenkins']['executor']['private_key'] = master['jenkins']['private_key']
  #
  # Or you could set it from a data bag:
  #
  #   private_key = encrypted_data_bag_item('jenkins', 'keys')['private_key']
  #   node.set['jenkins']['executor']['private_key'] = private_key
  #
  # Please see the +Authentication+ section of the README for more information.
  #
  executor['private_key'] = nil

  #
  # If you need to pass through a proxy to communicate between your masters and
  # slaves, you will need to set this node attribute. It should be  set in the
  # form `HOST:PORT`:
  #
  #   node.set['jenkins']['executor']['proxy'] = '1.2.3.4'
  #
  # Please see the +Proxies+ section of the README for more information.
  #
  executor['proxy'] = nil
end
