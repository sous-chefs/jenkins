#
# Custom jenkins_user matcher
#
module Serverspec
  module Type
    # rubocop:disable PredicateName
    class JenkinsJob < Base
      require 'rexml/document'

      attr_reader :name

      def initialize(name)
        @name = name
        super
      end

      def jenkins_job?
        !xml.nil?
      end

      def disabled?
        (try { xml.elements['//disabled'].text.to_s == 'true' }) != (nil || false)
      end

      def enabled?
        !disabled?
      end

      def has_command?(command)
        command == try { xml.elements['//command'].text }.strip
      end

      def has_plugin_like?(rx)
        plugin = try { xml.root.attributes['plugin'] }
        plugin.nil? ? false : plugin =~ rx
      end

      private

      def xml
        return @xml if @xml

        contents = ::File.read("/var/lib/jenkins/jobs/#{name}/config.xml")
        @xml = REXML::Document.new(contents)
      rescue Errno::ENOENT
        @xml = nil
      end

      def try(&_block)
        yield
      rescue NoMethodError
        nil
      end
    end
  end
end
