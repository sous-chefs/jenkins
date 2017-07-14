#
# Cookbook:: jenkins
# Recipe:: master
#
# Author: AJ Christensen <aj@junglist.gen.nz>
# Author: Dough MacEachern <dougm@vmware.com>
# Author: Fletcher Nichol <fnichol@nichol.ca>
# Author: Seth Chisamore <schisamo@chef.io>
# Author: Guilhem Lettron <guilhem.lettron@youscribe.com>
# Author: Seth Vargo <sethvargo@gmail.com>
#
# Copyright:: 2010-2016, VMWare, Inc.
# Copyright:: 2013-2016, Youscribe.
# Copyright:: 2012-2017, Chef Software, Inc.
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

# Gracefully handle the failure for an invalid installation type
begin
  include_recipe "jenkins::_master_#{node['jenkins']['master']['install_method']}"
rescue Chef::Exceptions::RecipeNotFound
  raise Chef::Exceptions::RecipeNotFound, 'The install method ' \
    "`#{node['jenkins']['master']['install_method']}' is not supported by " \
    'this cookbook. Please ensure you have spelled it correctly. If you ' \
    'continue to encounter this error, please file an issue.'
end
