#
# Custom jenkins_credentials matcher
#
module Serverspec
  module Type
    # rubocop:disable PredicateName
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
        !xml.nil?
      end

      def has_id?(id)
        id == try { xml.elements['id'].text }
      end

      private

      def try(&_block)
        yield
      rescue NoMethodError
        nil
      end
    end

    class JenkinsUserCredentials < JenkinsCredentials
      attr_reader :username

      def initialize(username)
        @username = username
        super
      end

      def has_description?(description)
        description == try { xml.elements['description'].text }
      end

      # TODO: encrypt provided password and compare to Jenkins value
      def has_password?(_password)
        !(try { xml.elements['password'].text }).nil?
      end

      def has_private_key?(private_key, passphrase = nil)
        pk_in_jenkins = xml.elements['privateKeySource/privateKey'].text

        if pk_in_jenkins
          if private_key.include?('BEGIN EC PRIVATE KEY')
            OpenSSL::PKey::EC.new(private_key, passphrase).to_der == OpenSSL::PKey::EC.new(pk_in_jenkins, passphrase).to_der
          else
            OpenSSL::PKey::RSA.new(private_key, passphrase).to_der == OpenSSL::PKey::RSA.new(pk_in_jenkins, passphrase).to_der
          end
        else
          false
        end
      end

      # TODO: encrypt provided passphrase and compare to Jenkins value
      def has_passphrase?(_passphrase)
        !(try { xml.elements['passphrase'].text }).nil?
      end

      private

      def xml
        return @xml if @xml

        contents = ::File.read('/var/lib/jenkins/credentials.xml')
        doc = REXML::Document.new(contents)
        @xml = REXML::XPath.first(doc, "//*[username/text() = '#{username}']/")
      rescue Errno::ENOENT
        @xml = nil
      end
    end

    class JenkinsSecretTextCredentials < JenkinsCredentials
      attr_reader :description

      def initialize(description)
        @description = description
        super
      end

      # TODO: encrypt provided secret and compare to Jenkins value
      def has_secret?(_secret)
        !(try { xml.elements['secret'].text }).nil?
      end

      private

      def xml
        return @xml if @xml

        contents = ::File.read('/var/lib/jenkins/credentials.xml')
        doc = REXML::Document.new(contents)
        @xml = REXML::XPath.first(doc, "//*[description/text() = '#{description}']/")
      rescue Errno::ENOENT
        @xml = nil
      end
    end
  end
end
