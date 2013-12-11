#
# Cookbook Name:: jenkins
# HWRP:: user
#
# Author:: Seth Vargo <sethvargo@gmail.com>
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

#
#
#
class Chef
  class Resource::JenkinsUser < Resource
    identity_attr :id

    attr_writer :exists

    def initialize(id, run_context = nil)
      super

      # Set the resource name and provider
      @resource_name = :jenkins_user
      @provider = Provider::JenkinsUser

      # Set default actions and allowed actions
      @action = :create
      @allowed_actions.push(:create, :delete)

      # Set the name attribute and default attributes
      @id          = id
      @public_keys = []

      # State attributes that are set by the provider
      @exists = false
    end

    #
    # The id of the user to create. This must be a unique id.
    #
    # @param [String] arg
    # @return [String]
    #
    def id(arg = nil)
      set_or_return(:id, arg, kind_of: String)
    end

    #
    # The full name of the user to create.
    #
    # @param [String] arg
    # @return [String]
    #
    def full_name(arg = nil)
      set_or_return(:full_name, arg, kind_of: String)
    end

    #
    # The email address of the user.
    #
    # @param [String] arg
    # @return [String]
    #
    def email(arg = nil)
      set_or_return(:source, arg, kind_of: String)
    end

    #
    # The list of public keys for this user.
    #
    # @param [String, Array<String>] arg
    # @return [Array<String>]
    #
    def public_keys(arg = nil)
      if arg.nil?
        @public_keys
      else
        @public_keys += Array(arg).compact.map(&:to_s)
      end
    end

    #
    # Determine if the user exists on the server. This value is set by
    # the provider when the current resource is loaded.
    #
    # @return [Boolean]
    #
    def exists?
      !!@exists
    end
  end
end

#
#
#
class Chef
  class Provider::JenkinsUser < Provider
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
    end

    #
    # This provider supports why-run mode.
    #
    def whyrun_supported?
      true
    end

    #
    # Create the given user.
    #
    def action_create
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

            keys = new org.jenkinsci.main.modules.cli.auth.ssh.UserPropertyImpl('#{new_resource.public_keys.join("\n")}')
            user.addProperty(keys)

            user.save()
          EOH
        end
      end
    end

    #
    # Delete the given user.
    #
    def action_delete
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
