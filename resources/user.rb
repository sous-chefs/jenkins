#
# Cookbook:: jenkins
# Resource:: user
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

require 'json'

unified_mode true

provides :jenkins_user

property :id, String, name_property: true
property :full_name, String
property :email, String
property :public_keys, Array, default: []
property :password, String

load_current_value do |new_resource|
  current_user = current_user_from_jenkins

  if current_user
    full_name current_user[:full_name]
    email current_user[:email]
    public_keys current_user[:public_keys]
  else
    current_value_does_not_exist!
  end
end

action :create do
  if current_resource &&
     (new_resource.full_name.nil? || current_resource.full_name == new_resource.full_name) &&
     (new_resource.email.nil? || current_resource.email == new_resource.email) &&
     current_resource.public_keys == new_resource.public_keys
    Chef::Log.info("#{new_resource} exists - skipping")
  else
    converge_by("Create #{new_resource}") do
      executor.groovy! <<-EOH.gsub(/^ {8}/, '')
        user = hudson.model.User.get('#{new_resource.id}')
        user.setFullName('#{new_resource.full_name}')

        if (jenkins.model.Jenkins.instance.pluginManager.getPlugin('mailer')) {
          propertyClass = this.class.classLoader.loadClass('hudson.tasks.Mailer$UserProperty')
          email = propertyClass.newInstance('#{new_resource.email}')
          user.addProperty(email)
        }

        password = hudson.security.HudsonPrivateSecurityRealm.Details.fromPlainPassword('#{new_resource.password}')
        user.addProperty(password)

        keys = new org.jenkinsci.main.modules.cli.auth.ssh.UserPropertyImpl('#{new_resource.public_keys.join('\n')}')
        user.addProperty(keys)

        user.save()
      EOH
    end
  end
end

action :delete do
  if current_resource
    converge_by("Delete #{new_resource}") do
      executor.groovy! <<-EOH.gsub(/^ {8}/, '')
        user = hudson.model.User.get('#{new_resource.id}', false)
        user.delete()
      EOH
    end
  else
    Chef::Log.debug("#{new_resource} does not exist - skipping")
  end
end

action_class do
  include Jenkins::Helper

  #
  # Loads the local user into a hash
  #
  def current_user_from_jenkins
    return @current_user if @current_user

    Chef::Log.debug "Load #{new_resource} user information"

    json = executor.groovy <<-EOH.gsub(/^ {6}/, '')
      user = hudson.model.User.get('#{new_resource.id}', false)

      if(user == null) {
        return null
      }

      id = user.getId()
      name = user.getFullName()

      email = null
      emailProperty = user.getProperty(hudson.tasks.Mailer.UserProperty)
      if(emailProperty != null) {
        email = emailProperty.getAddress()
      }

      keys = null
      keysProperty = user.getProperty(org.jenkinsci.main.modules.cli.auth.ssh.UserPropertyImpl)
      if(keysProperty != null) {
        keys = keysProperty.authorizedKeys.split('\\n') - "" // Remove empty strings
      }

      builder = new groovy.json.JsonBuilder()
      builder {
        id id
        full_name name
        email email
        public_keys keys
      }

      println(builder)
    EOH

    return if json.nil? || json.empty?

    @current_user = JSON.parse(json, symbolize_names: true)
    @current_user
  end
end
