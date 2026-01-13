require 'json'

unified_mode true

resource_name :jenkins_proxy
provides :jenkins_proxy

property :proxy, String, name_property: true
property :noproxy, Array, default: []
property :username, String
property :password, String

load_current_value do |_new_resource|
  current_proxy = current_proxy_from_jenkins

  if current_proxy
    proxy current_proxy[:proxy]
    noproxy current_proxy[:noproxy]
    # NOTE: username and password are not returned by current_proxy_from_jenkins
  else
    current_value_does_not_exist!
  end
end

action :config do
  if current_resource &&
     current_resource.proxy == new_resource.proxy &&
     current_resource.noproxy == new_resource.noproxy
    # NOTE: We can't check username/password as they're not returned from Jenkins
    Chef::Log.info("#{new_resource} already configured - skipping")
  else
    name, port = new_resource.proxy.split(':')
    if name && port && port.to_i > 0
      converge_by("Configure #{new_resource}") do
        executor.groovy! <<-EOH.gsub(/^ {10}/, '')
          name = #{convert_to_groovy(name)}
          port = #{convert_to_groovy(port.to_i)}
          username = #{convert_to_groovy(new_resource.username)}
          password = #{convert_to_groovy(new_resource.password)}
          noproxy = '#{new_resource.noproxy.join('\n')}'

          import hudson.ProxyConfiguration
          def pc = new ProxyConfiguration(name, port, username, password, noproxy)
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

action :remove do
  if current_resource
    converge_by("Remove #{new_resource}") do
      executor.groovy! <<-EOH.gsub(/^ {8}/, '')
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

action_class do
  include Jenkins::Helper

  #
  # Loads the local proxy into a hash
  #
  def current_proxy_from_jenkins
    return @current_proxy if @current_proxy

    Chef::Log.debug "Load #{new_resource} proxy information"

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
end
