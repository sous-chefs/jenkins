#
# Cookbook Name:: jenkins
# Provider:: cli
#
# Author:: Doug MacEachern <dougm@vmware.com>
# Author:: Fletcher Nichol <fnichol@nichol.ca>
#
# Copyright:: 2010, VMware, Inc.
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

#
# @todo Deprecate this in the next major release.
#
action :run do
  replace = Chef::Resource::JenkinsCommand.new(new_resource.name, run_context)
  new_resource.instance_variables.each do |instance_variable|
    value = new_resource.instance_variable_get(instance_variable)
    replace.instance_variable_set(instance_variable, value)
  end

  Chef::Log.warn <<-EOH
[DEPRECATED] jenkins_cli is deprecated. Please use jenkins_command instead:

#{replace.to_text}
EOH

  replace.run_action(:execute)
end
