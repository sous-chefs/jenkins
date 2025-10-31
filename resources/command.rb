#
# Cookbook:: jenkins
# Resource:: command
#
# Author:: Seth Vargo <sethvargo@gmail.com>
#
# Copyright:: 2013-2019, Chef Software, Inc.
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

provides :jenkins_command

property :command, String, name_property: true

action :execute do
  converge_by("Execute #{new_resource}") do
    executor.execute!(new_resource.command)
  end
end

action_class do
  include Jenkins::Helper
end
