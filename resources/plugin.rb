#
# Cookbook Name:: jenkins
# Resource:: plugin
#
# Copyright 2013, Opscode, Inc.
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

actions :install, :remove
default_action :install

attribute :version, :kind_of => String
attribute :url, :kind_of => String

# If url isn't specified, a default URL based on the plugin name and version is returned
def url(arg = nil)
  if arg.nil? && @url.nil?
    "#{node['jenkins']['mirror']}/plugins/#{name}/#{version}/#{name}.hpi"
  else
    set_or_return(:url, arg, :kind_of => String)
  end
end
