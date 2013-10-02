#
# Cookbook Name:: jenkins
# Provider:: job
#
# Author:: Doug MacEachern <dougm@vmware.com>
# Author:: Fletcher Nichol <fnichol@nichol.ca>
# Author:: Seth Chisamore <schisamo@opscode.com>
#
# Copyright:: 2010, VMware, Inc.
# Copyright:: 2012, Opscode, Inc.
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

def load_current_resource
  @current_resource = Chef::Resource::JenkinsJob.new(@new_resource.name)
  @jenkins_client = initialize_client
end

def store
  validate_job_config!
  @jenkins_client.job.create(
    @new_resource.job_name,
    IO.read(@new_resource.config)
  )
  new_resource.updated_by_last_action(true)
end

alias_method :action_create, :store
alias_method :action_update, :store

def action_delete
  @jenkins_client.job.delete(@new_resource.job_name) if @jenkins_client.job.exists?(@new_resource.job_name)
end

def action_disable
  @jenkins_client.job.disable(@new_resource.job_name)
end

def action_enable
  @jenkins_client.job.enable(@new_resource.job_name)
end

def action_build
  @jenkins_client.job.build(@new_resource.job_name, @new_resource.build_params)
end

private

def validate_job_config!
  unless ::File.exist?(@new_resource.config)
    raise "'#{@new_resource.config}' does not exist or is not a valid Jenkins config file!"
  end
end

def initialize_client
  begin
    require "jenkins_api_client"
  rescue LoadError => e
    Chef::Log.error "Unable to load the 'jenkins_api_client' gem." +
      " Make sure to run jenkins::server recipe before using the provider"
    raise e
  end
  client = JenkinsApi::Client.new(
    :server_url => @new_resource.url,
    :username => node['jenkins']['username'],
    :password => node['jenkins']['password']
  )
  client.logger = Chef::Log
  client
end
