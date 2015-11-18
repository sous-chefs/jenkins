module RSpec
  module Core
    #
    module DSL
      def jenkins_build(name, number)
        Serverspec::Type::JenkinsBuild.new(name, number)
      end

      def jenkins_job(name)
        Serverspec::Type::JenkinsJob.new(name)
      end

      def jenkins_plugin(name)
        Serverspec::Type::JenkinsPlugin.new(name)
      end

      def jenkins_secret_text_credentials(description)
        Serverspec::Type::JenkinsSecretTextCredentials.new(description)
      end

      def jenkins_slave(name)
        Serverspec::Type::JenkinsSlave.new(name)
      end

      def jenkins_user(id)
        Serverspec::Type::JenkinsUser.new(id)
      end

      def jenkins_user_credentials(username)
        Serverspec::Type::JenkinsUserCredentials.new(username)
      end
    end
  end
end

extend RSpec::Core::DSL
Module.send(:include, RSpec::Core::DSL)
