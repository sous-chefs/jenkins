#
# Custom jenkins_user matcher
#
module Serverspec
  module Type
    class JenkinsJob < Base
      require 'rexml/document'

      attr_reader :name

      def initialize(name)
        @name = name
        super
      end

      def jenkins_job?
        !!xml
      end

      def disabled?
        !!try { xml.elements['//disabled'].text.to_s == 'true' }
      end

      def enabled?
        !disabled?
      end

      def has_command?(command)
        command === try { xml.elements['//command'].text }
      end

      private

      def xml
        return @xml if @xml

        contents = ::File.read("/var/lib/jenkins/jobs/#{name}/config.xml")
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
