#
# Custom jenkins_credentials matcher
#
module Serverspec
  module Type
    # rubocop:disable PredicateName, CaseEquality
    class JenkinsCredentials < Base
      require 'openssl'
      require 'rexml/document'
      require 'rexml/xpath'

      attr_reader :username

      def initialize(username)
        @username = username
        super
      end

      def jenkins_credentials?
        !!xml
      end

      def has_id?(id)
        id === try { xml.elements['id'].text }
      end

      def has_description?(description)
        description === try { xml.elements['description'].text }
      end

      # TODO: encrypt provided password and compare to Jenkins value
      def has_password?(password)
        !(try { xml.elements['password'].text }).nil?
      end

      def has_private_key?(private_key, passphrase=nil)
        pk_in_jenkins = xml.elements['privateKeySource/privateKey'].text

        if pk_in_jenkins
          OpenSSL::PKey::RSA.new(private_key, passphrase).to_der === OpenSSL::PKey::RSA.new(pk_in_jenkins, passphrase).to_der
        else
          false
        end
      end

      # TODO: encrypt provided passphrase and compare to Jenkins value
      def has_passphrase?(passphrase)
        !(try { xml.elements['passphrase'].text }).nil?
      end

      private

      def xml
        return @xml if @xml

        contents = ::File.read("/var/lib/jenkins/credentials.xml")
        doc = REXML::Document.new(contents)
        @xml = REXML::XPath.first(doc, "//*[username/text() = '#{username}']/")
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
