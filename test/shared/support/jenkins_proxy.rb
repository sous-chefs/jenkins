#
# Custom jenkins_proxy matcher
#
module Serverspec
  module Type
    class JenkinsProxy < Base
      require 'rexml/document'

      attr_reader :id

      def initialize(id)
        @id = id
        super
      end

      def jenkins_proxy?
        !!xml
      end

      def has_name?(name)
        name === try { xml.elements['//name'].text }
      end

      def has_port?(port)
        port === try { xml.elements['//port'].text.to_i }
      end

      def has_noproxy?(noproxy)
        noproxies = try { xml.elements['//noProxyHost'].text.split("\n").map(&:strip) } || []
        noproxies.include?(noproxy.to_s)
      end

      private

      def xml
        return @xml if @xml

        contents = ::File.read("/var/lib/jenkins/proxy.xml")
        @xml = REXML::Document.new(contents)
      rescue Errno::ENOENT
        @xml = nil
      end

      def try(&block)
        block.call
      rescue NoMethodError
        nil
      end
    end
  end
end
