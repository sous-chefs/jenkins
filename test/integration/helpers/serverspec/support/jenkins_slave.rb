#
# Custom jenkins_slave matcher
#
module Serverspec
  module Type
    # rubocop:disable PredicateName
    class JenkinsSlave < Base
      require 'json'
      require 'net/http'
      require 'rexml/document'

      attr_reader :name

      def initialize(name)
        @name = name
        super
      end

      def jenkins_slave?
        !xml.nil?
      end

      def connected?
        !json[:offline]
      end

      def online?
        !json[:temporarilyOffline]
      end

      ############################################
      # Base Slave Attributes
      ############################################
      def has_description?(description)
        description == try { xml.elements['//description'].text }
      end

      def has_remote_fs?(remote_fs)
        remote_fs == try { xml.elements['//remoteFS'].text }
      end

      def has_labels?(labels)
        all_labels = try { xml.elements['//label'].text.split(' ').map(&:strip) } || []
        !(all_labels & labels).empty?
      end

      def has_usage_mode?(mode)
        mode.casecmp(try { xml.elements['//mode'].text }.downcase) == 0
      end

      def has_availability?(availability)
        # returns something like `hudson.slaves.RetentionStrategy$Always`
        retention_class = try { xml.elements['//retentionStrategy'].attributes['class'] }
        type = retention_class.split('$').last
        availability.casecmp(type.downcase) == 0
      end

      def has_in_demand_delay?(in_demand_delay)
        in_demand_delay == try { xml.elements['//inDemandDelay'].text }.to_i
      end

      def has_idle_delay?(idle_delay)
        idle_delay == try { xml.elements['//idleDelay'].text }.to_i
      end

      def has_environment?(environment)
        environment.all? do |k, v|
          value_in_jenkins = REXML::XPath.first(xml, "//*/string[text()='#{k}']/following-sibling::string[1]").text
          v.to_s == value_in_jenkins
        end
      end

      ############################################
      # SSH Slave Attributes
      ############################################
      def has_host?(host)
        host == try { xml.elements['//host'].text }
      end

      def has_port?(port)
        port == try { xml.elements['//port'].text.to_i }
      end

      def has_java_path?(path)
        path == try { xml.elements['//javaPath'].text }
      end

      def has_credentials?(credentials)
        credentials_id = try { xml.elements['//credentialsId'].text }
        credentials_xml = credentials_xml_for_id(credentials_id)
        credentials == if credentials =~ /[a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[89aAbB][a-f0-9]{3}-[a-f0-9]{12}/ # UUID regex
                         try { credentials_xml.elements['id'].text }
                       else
                         try { credentials_xml.elements['username'].text }
                       end
      end

      def has_launch_timeout?(launch_timeout)
        launch_timeout == try { xml.elements['//launchTimeoutSeconds'].text.to_i }
      end

      def has_ssh_retries?(ssh_retries)
        ssh_retries == try { xml.elements['//maxNumRetries'].text.to_i }
      end

      def has_ssh_wait_retries?(ssh_wait_retries)
        ssh_wait_retries == try { xml.elements['//retryWaitTime'].text.to_i }
      end

      ############################################
      # Offline Attributes
      ############################################
      def has_offline_reason?(reason)
        reason == json[:offlineCauseReason]
      end

      private

      def xml
        return @xml if @xml

        config_url = "http://localhost:8080/computer/#{name}/config.xml"
        response = Net::HTTP.get_response(URI.parse(config_url))

        @xml = if response.is_a?(Net::HTTPNotFound)
                 nil
               # If authn is enabled fall back to reading main config from disk
               elsif response.is_a?(Net::HTTPForbidden)
                 # attempt to read from dedicated slave xml file first
                 config_path = "/var/lib/jenkins/nodes/#{name}/config.xml"

                 if ::File.exist?(config_path)
                   contents = ::File.read(config_path)
                   REXML::Document.new(contents)
                 # Fall back to reading from the main config xml
                 else
                   contents = ::File.read('/var/lib/jenkins/config.xml')
                   config_xml = REXML::Document.new(contents)
                   REXML::Document.new(config_xml.elements["//slave[name='#{name}']"].to_s)
                 end
               else
                 REXML::Document.new(response.body)
               end
      end

      def json
        return @json if @json

        config_url = "http://localhost:8080/computer/#{name}/api/json?pretty=true"
        response = Net::HTTP.get_response(URI.parse(config_url))

        @json = if response.is_a? Net::HTTPNotFound
                  nil
                else
                  JSON.parse(response.body, symbolize_names: true)
                end
      end

      def credentials_xml_for_id(credentials_id)
        contents = ::File.read('/var/lib/jenkins/credentials.xml')
        doc = REXML::Document.new(contents)
        REXML::XPath.first(doc, "//*[id/text() = '#{credentials_id}']/")
      rescue Errno::ENOENT
        nil
      end

      def try(&_block)
        yield
      rescue NoMethodError
        nil
      end
    end
  end
end
