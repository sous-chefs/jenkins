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

      attr_reader :id

      def initialize(id)
        @id = id
        super
      end

      def jenkins_credentials?
        !xml.nil?
      end

      def has_id?(id)
        id == try { xml.elements['id'].text }
      end

      protected

      def xml
        return @xml if @xml

        contents = ::File.read('/var/lib/jenkins/credentials.xml')
        doc = REXML::Document.new(contents)
        @xml = REXML::XPath.first(doc, "//*[id/text() = '#{id}']/")
      rescue Errno::ENOENT
        @xml = nil
      end

      private

      def try(&_block)
        yield
      rescue NoMethodError
        nil
      end
    end

    class JenkinsUserCredentials < JenkinsCredentials
      def has_description?(description)
        description == try { xml.elements['description'].text }
      end

      def has_username?(username)
        username == try { xml.elements['username'].text }
      end

      # TODO: encrypt provided password and compare to Jenkins value
      def has_password?(_password)
        !(try { xml.elements['password'].text }).nil?
      end

      # http://xn--thibaud-dya.fr/jenkins_credentials.html the private
      # key is encoded specially by Jenkins. Short of porting the
      # decryption algorithm in Ruby, we could query Jenkins for the
      # actual credentials, which would make the tests longer.
      def has_private_key?(_private_key, _passphrase = nil)
        !(try { xml.elements['privateKeySource/privateKey'].text }).nil?
      end

      # TODO: encrypt provided passphrase and compare to Jenkins value
      def has_passphrase?(_passphrase)
        !(try { xml.elements['passphrase'].text }).nil?
      end
    end

    class JenkinsSecretTextCredentials < JenkinsCredentials
      # TODO: encrypt provided secret and compare to Jenkins value
      def has_secret?(_secret)
        !(try { xml.elements['secret'].text }).nil?
      end
    end
  end
end
