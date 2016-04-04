#
# Custom jenkins_user matcher
#
module Serverspec
  module Type
    # rubocop:disable PredicateName
    class JenkinsUser < Base
      require 'rexml/document'

      attr_reader :id

      def initialize(id)
        @id = id
        super
      end

      def jenkins_user?
        !xml.nil?
      end

      def has_email?(email)
        email == try { xml.elements['//emailAddress'].text }
      end

      def has_full_name?(name)
        name == try { xml.elements['//fullName'].text }
      end

      def has_public_key?(key)
        keys = try { xml.elements['//authorizedKeys'].text.split("\n").map(&:strip) } || []
        keys.include?(key.to_s)
      end

      def password_hash
        try { xml.elements['//passwordHash'].text }
      end

      private

      def xml
        return @xml if @xml

        contents = ::File.read("/var/lib/jenkins/users/#{id}/config.xml")
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
