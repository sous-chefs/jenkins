#
# Cookbook:: jenkins
# Recipe:: java
#
# Author: Seth Vargo <sethvargo@chef.io>
#
# Copyright:: 2014-2019, Chef Software, Inc.
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
# This is a very basic recipe for installing Java on the target system. It is
# NOT included in any recipes by default. The purpose of this cookbook is to
# install Jenkins, not manage a Java. For complex Java scenarios, you should
# use the Java community cookbook or construct your own.
#
# Do NOT submit patches adding support for additional platforms
# Do NOT submit patches adding support for installing Java derivatives
# Do NOT submit patches adding support for installing different Java versions
#
# This recipe is not included by default, and you have no obligation to use it.
# We are going to be incredibly opinionated about what this recipe includes, as
# it is a minimum viable cookbook for installing Java. If you need a more
# complex scenario, that is outside the scope of this cookbook.
#

Chef::Log.warn('The jenkins::java recipe has been deprecated. We recommend adding the Java cookbook to the runlist of your jenkins node instead as it provides more tuneables')

case node['platform_family']
when 'debian'
  package 'openjdk-8-jdk'
when 'rhel', 'amazon', 'fedora'
  package 'java-1.8.0-openjdk'
else
  raise "`#{node['platform_family']}' is not supported!"
end
