#
# Cookbook:: jenkins
# Library:: proxy_helpers
#

require_relative '_helper'

module Jenkins
  module ProxyHelpers
    include Jenkins::Helper

    #
    # Loads the local proxy into a hash
    #
    def current_proxy_from_jenkins(resource = proxy_resource)
      return @current_proxy if @current_proxy

      Chef::Log.debug "Load #{resource} proxy information"

      json = executor.groovy <<-EOH.gsub(/^ {6}/, '')
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

      return if json.nil? || json.empty?

      @current_proxy = JSON.parse(json, symbolize_names: true)
      @current_proxy
    end

    private

    def proxy_resource
      respond_to?(:new_resource) && new_resource ? new_resource : self
    end
  end
end
