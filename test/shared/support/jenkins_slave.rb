#
# Custom jenkins_slave matcher
#
module Serverspec
  module Type
    # rubocop:disable PredicateName, CaseEquality
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
        !!xml
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
        description === try { xml.elements['//description'].text }
      end

      def has_remote_fs?(remote_fs)
        remote_fs === try { xml.elements['//remoteFS'].text }
      end

      def has_labels?(labels)
        all_labels = try { xml.elements['//label'].text.split("\s").map(&:strip) } || []
        !(all_labels & labels).empty?
      end

      def has_usage_mode?(mode)
        mode.downcase === try { xml.elements['//mode'].text }.downcase
      end

      def has_availability?(availability)
        # returns something like `hudson.slaves.RetentionStrategy$Always`
        retention_class = try { xml.elements['//retentionStrategy'].attributes['class'] }
        type = retention_class.split('$').last
        availability.downcase === type.downcase
      end

      def has_in_demand_delay?(in_demand_delay)
        in_demand_delay === try { xml.elements['//inDemandDelay'].text }.to_i
      end

      def has_idle_delay?(idle_delay)
        idle_delay === try { xml.elements['//idleDelay'].text }.to_i
      end

      def has_environment?(environment)
        environment.all? do |k, v|
          value_in_jenkins = REXML::XPath.first(xml, "//*/string[text()='#{k}']/following-sibling::string[1]").text
          v.to_s === value_in_jenkins
        end
      end

      ############################################
      # SSH Slave Attributes
      ############################################
      def has_host?(host)
        host === try { xml.elements['//host'].text }
      end

      def has_port?(port)
        port === try { xml.elements['//port'].text.to_i }
      end

      def has_credentials?(credentials)
        credentials_id = try { xml.elements['//credentialsId'].text }
        credentials_xml = credentials_xml_for_id(credentials_id)
        if credentials =~ /[a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[89aAbB][a-f0-9]{3}-[a-f0-9]{12}/ # UUID regex
          credentials === try { credentials_xml.elements['id'].text }
        else
          credentials === try { credentials_xml.elements['username'].text }
        end
      end

      ############################################
      # Offline Attributes
      ############################################
      def has_offline_reason?(reason)
        reason === json[:offlineCauseReason]
      end

      private

      def xml
        return @xml if @xml

        config_url = "http://localhost:8080/computer/#{name}/config.xml"
        response = Net::HTTP.get_response(URI.parse(config_url))

        @xml = if response.kind_of? Net::HTTPNotFound
                 nil
               else
                 REXML::Document.new(response.body)
               end
      end

      def json
        return @json if @json

        config_url = "http://localhost:8080/computer/#{name}/api/json?pretty=true"
        response = Net::HTTP.get_response(URI.parse(config_url))

        @json = if response.kind_of? Net::HTTPNotFound
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

      def try(&block)
        block.call
      rescue NoMethodError
        nil
      end
    end
  end
end
