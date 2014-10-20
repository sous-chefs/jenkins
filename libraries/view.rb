#
# Cookbook Name:: jenkins
# HWRP:: view
#
# Author:: Don Luchini (dluchini@enernoc.com)
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
  class Resource::JenkinsView < Resource::LWRPBase
    # Chef attributes
    identity_attr :name
    provides :jenkins_view

    # Set the resource name
    self.resource_name = :jenkins_view

    # Actions
    actions :create, :delete
    default_action :create

    # Attributes
    attribute :name,
      kind_of: String,
      name_attribute: true
    attribute :regex,
      kind_of: String

    attr_writer :exists

    #
    # Determine if the view exists on the master. This value is set by
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
  class Provider::JenkinsView < Provider::LWRPBase
    require 'json'
    include Jenkins::Helper

    def load_current_resource
      @current_resource ||= Resource::JenkinsView.new(new_resource.name)

      if current_view
        @current_resource.exists = true
        @current_resource.name(current_view[:name])
        @current_resource.regex(current_view[:regex])
      end

      @current_resource
    end

    def whyrun_supported?
      true
    end

    action(:create) do
      if current_resource.exists? &&
         current_resource.name  == new_resource.name  &&
         current_resource.regex == new_resource.regex
        Chef::Log.debug("#{new_resource} exists - skipping")
      else
        converge_by("Create #{new_resource}") do
          executor.groovy! <<-EOH.gsub(/ ^{12}/, '')
            view = hudson.model.Hudson.instance.getView("#{new_resource.name}")
            
            if(view == null) {
              hudson.model.Hudson.instance.addView(new hudson.model.ListView("#{new_resource.name}"))
              view = hudson.model.Hudson.instance.getView("#{new_resource.name}")
            }
            
            view.setIncludeRegex("#{new_resource.regex}")
            
            view.save()
          EOH
        end
      end
    end

    action(:delete) do
      if current_resource.exists?
        converge_by("Delete #{new_resource}") do
          executor.groovy! <<-EOH.gsub(/^ {12}/, '')
            hudson.model.Hudson.instance.deleteView(hudson.model.Hudson.instance.getView("#{new_resource.name}"))
          EOH
        end
      else
        Chef::Log.debug("#{new_resource} does not exist - skipping")
      end
    end

    private

    #
    # Loads the view into a hash
    #
    def current_view
      return @current_view if @current_view

      Chef::Log.debug "Load #{new_resource} view information"

      json = executor.groovy <<-EOH.gsub(/ ^{8}/, '')
        view = hudson.model.Hudson.instance.getView("#{new_resource.name}")

        if(view == null) {
          return null
        }

        builder = new groovy.json.JsonBuilder()
        builder {
          name view.getDisplayName()
          regex view.getIncludeRegex()
        }

        println(builder)
      EOH

      return nil if json.nil? || json.empty?

      @current_view = JSON.parse(json, symbolize_names: true)
      @current_view
    end
  end
end

Chef::Platform.set(
  resource: :jenkins_view,
  provider: Chef::Provider::JenkinsView
)
