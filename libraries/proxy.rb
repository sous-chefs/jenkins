#
# Cookbook:: jenkins
# Resource:: proxy
#
# Author:: Stephan Linz <linz@li-pro.net>
#
# Copyright:: 2014-2019, Li-Pro.Net
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

require_relative '_helper'
require_relative '_params_validate'

class Chef
  class Resource::JenkinsProxy < Resource::LWRPBase
    resource_name :jenkins_proxy # Still needed for Chef 15 and below
    provides :jenkins_proxy

    # Chef attributes
    identity_attr :proxy

    # Actions
    actions :config, :remove
    default_action :config

    # Attributes
    attribute :proxy,
              kind_of: String,
              name_attribute: true
    attribute :noproxy,
              kind_of: Array,
              default: []

    attr_writer :configured

    #
    # Determine if the proxy is configured on the master. This value is set by
    # the provider when the current resource is loaded.
    #
    # @return [Boolean]
    #
    def configured?
      !@configured.nil? && @configured
    end
  end
end

class Chef
  class Provider::JenkinsProxy < Provider::LWRPBase
    include Jenkins::Helper

    provides :jenkins_proxy

    def load_current_resource
      @current_resource ||= Resource::JenkinsProxy.new(new_resource.proxy)

      if current_proxy
        @current_resource.configured = true
        @current_resource.proxy(current_proxy[:proxy])
        @current_resource.noproxy(current_proxy[:noproxy])
      end

      @current_resource
    end

    action(:config) do
      if current_resource.configured? &&
         current_resource.proxy == new_resource.proxy &&
         current_resource.noproxy == new_resource.noproxy
        Chef::Log.info("#{new_resource} already configured - skipping")
      else
        name, port = new_resource.proxy.split(':')
        if name && port && port.to_i > 0
          converge_by("Configure #{new_resource}") do
            executor.groovy! <<-EOH.gsub(/^ {14}/, '')
              name = #{convert_to_groovy(name)}
              port = #{convert_to_groovy(port.to_i)}
              noproxy = '#{new_resource.noproxy.join('\n')}'

              import hudson.ProxyConfiguration
              def pc = new ProxyConfiguration(name, port, null, null, noproxy)
              pc.save()

              import jenkins.model.Jenkins
              def instance = Jenkins.getInstance()
              instance.proxy = pc.load()
            EOH
          end
        else
          Chef::Log.debug("#{new_resource} incorrect format - skipping")
        end
      end
    end

    action(:remove) do
      if current_resource.configured?
        converge_by("Remove #{new_resource}") do
          executor.groovy! <<-EOH.gsub(/^ {12}/, '')
            import jenkins.model.Jenkins
            def instance = Jenkins.getInstance()

            def pc = instance.proxy
            if (pc == null) {
              return null
            }

            pc.getXmlFile().delete()
            instance.proxy = pc.load()
          EOH
        end
      else
        Chef::Log.debug("#{new_resource} does not exist - skipping")
      end
    end

    private

    #
    # Loads the local proxy into a hash
    #
    def current_proxy
      return @current_proxy if @current_proxy

      Chef::Log.debug "Load #{new_resource} proxy information"

      json = executor.groovy <<-EOH.gsub(/^ {8}/, '')
        import java.util.Collections
        import java.util.List

        import jenkins.model.Jenkins
        def instance = Jenkins.getInstance()

        def pc = instance.proxy
        if (pc == null) {
          return null
        }

        def no_proxy = pc.noProxyHost
        if (no_proxy != null) {
          no_proxy = no_proxy.tokenize('[ \\t\\n,|]+')
        } else {
          no_proxy = Collections.emptyList()
        }

        def builder = new groovy.json.JsonBuilder()
        builder {
          proxy pc.name + ':' + pc.port.toString()
          noproxy no_proxy
        }

        println(builder)
      EOH

      return nil if json.nil? || json.empty?

      @current_proxy = JSON.parse(json, symbolize_names: true)
      @current_proxy
    end
  end
end
