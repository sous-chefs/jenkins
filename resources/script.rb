#
# Cookbook:: jenkins
# Resource:: script
#
# Author:: Seth Vargo <sethvargo@gmail.com>
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

unified_mode true

provides :jenkins_script

property :command, String
property :groovy_path, String

action :execute do
  converge_by("Execute script #{new_resource}") do
    if new_resource.groovy_path
      executor.groovy_from_file!(new_resource.groovy_path)
    else
      executor.groovy!(new_resource.command)
    end
  end
end

action_class do
  include Jenkins::Helper
end
