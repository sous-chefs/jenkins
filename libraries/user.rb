#
# Cookbook Name:: jenkins
# HWRP:: user
#
# Author:: Seth Vargo <sethvargo@gmail.com>
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

require_relative '_helper'
require_relative '_params_validate'

class Chef
  class Resource::JenkinsUser < Resource::LWRPBase
    # Chef attributes
    identity_attr :id
    provides :jenkins_user

    # Set the resource name
    self.resource_name = :jenkins_user

    # Actions
    actions :create, :delete
    default_action :create

    # Attributes
    attribute :id,
      kind_of: String,
      name_attribute: true
    attribute :full_name,
      kind_of: String
    attribute :email,
      kind_of: String
    attribute :public_keys,
      kind_of: Array,
      default: []
    attribute :password,
      kind_of: String

    attr_writer :exists

    #
    # Determine if the user exists on the master. This value is set by
    # the provider when the current resource is loaded.
    #
    # @return [Boolean]
    #
    def exists?
      !!@exists
    end
  end
end

class Chef
  class Provider::JenkinsUser < Provider::LWRPBase
    require 'json'
    include Jenkins::Helper

    def load_current_resource
      @current_resource ||= Resource::JenkinsUser.new(new_resource.id)

      if current_user
        @current_resource.exists = true
        @current_resource.full_name(current_user[:full_name])
        @current_resource.email(current_user[:email])
        @current_resource.public_keys(current_user[:public_keys])
      end

      @current_resource
    end

    def whyrun_supported?
      true
    end

    action(:create) do
      if current_resource.exists? &&
         current_resource.full_name  == new_resource.full_name  &&
         current_resource.email == new_resource.email &&
         current_resource.public_keys  == new_resource.public_keys
        Chef::Log.debug("#{new_resource} exists - skipping")
      else
        converge_by("Create #{new_resource}") do
          executor.groovy! <<-EOH.gsub(/ ^{12}/, '')
            user = hudson.model.User.get('#{new_resource.id}')
            user.setFullName('#{new_resource.full_name}')

            email = new hudson.tasks.Mailer.UserProperty('#{new_resource.email}')
            user.addProperty(email)

            password = hudson.security.HudsonPrivateSecurityRealm.Details.fromPlainPassword('#{new_resource.password}')
            user.addProperty(password)

            keys = new org.jenkinsci.main.modules.cli.auth.ssh.UserPropertyImpl('#{new_resource.public_keys.join("\n")}')
            user.addProperty(keys)

            user.save()
          EOH
        end
      end
    end

    action(:delete) do
      if current_resource.exists?
        converge_by("Delete #{new_resource}") do
          executor.groovy! <<-EOH.gsub(/^ {12}/, '')
            user = hudson.model.User.get('#{new_resource.id}', false)
            user.delete()
          EOH
        end
      else
        Chef::Log.debug("#{new_resource} does not exist - skipping")
      end
    end

    private

    #
    # Loads the local user into a hash
    #
    def current_user
      return @current_user if @current_user

      Chef::Log.debug "Load #{new_resource} user information"

      json = executor.groovy <<-EOH.gsub(/ ^{8}/, '')
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
          keys = keysProperty.authorizedKeys.split('\\\\\\\\s+') - "" // Remove empty strings
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

      return nil if json.nil? || json.empty?

      @current_user = JSON.parse(json, symbolize_names: true)
      @current_user
    end
  end
end

Chef::Platform.set(
  resource: :jenkins_user,
  provider: Chef::Provider::JenkinsUser
)
