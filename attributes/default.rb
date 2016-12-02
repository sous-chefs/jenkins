#
# Cookbook:: jenkins
# Attributes:: default
#
# Author: Doug MacEachern <dougm@vmware.com>
# Author: Fletcher Nichol <fnichol@nichol.ca>
# Author: Seth Chisamore <schisamo@chef.io>
# Author: Seth Vargo <sethvargo@gmail.com>
#
# Copyright:: 2010-2016, VMware, Inc.
# Copyright:: 2012-2016, Chef Software, Inc.
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

default['jenkins'].tap do |jenkins|
  #
  # The path to the +java+ bin on disk. This attribute is intelligently
  # calculated by assuming some sane defaults from community Java cookbooks:
  #
  #   - node['java']['java_home']
  #   - node['java']['home']
  #   - ENV['JAVA_HOME']
  #
  # These home's are then intelligently joined with +/bin/java+ for the full
  # path to the Java binary. If no +$JAVA_HOME+ is detected, +'java'+ is used
  # and it is assumed that the correct java binary exists in the +$PATH+.
  #
  # You can override this attribute by setting the full path manually:
  #
  #   node.normal['jenkins']['java'] = '/my/custom/path/to/java6'
  #
  # Setting this value to +nil+ will break the Internet.
  #
  jenkins['java'] = if node['java'] && node['java']['java_home']
                      File.join(node['java']['java_home'], 'bin', 'java')
                    elsif node['java'] && node['java']['home']
                      File.join(node['java']['home'], 'bin', 'java')
                    elsif ENV['JAVA_HOME']
                      File.join(ENV['JAVA_HOME'], 'bin', 'java')
                    else
                      'java'
                    end
end
