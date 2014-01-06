module RSpec
  module Core
    module DSL
      def jenkins_credentials(username)
        Serverspec::Type::JenkinsCredentials.new(username)
      end

      def jenkins_job(name)
        Serverspec::Type::JenkinsJob.new(name)
      end

      def jenkins_plugin(name)
        Serverspec::Type::JenkinsPlugin.new(name)
      end

      def jenkins_user(id)
        Serverspec::Type::JenkinsUser.new(id)
      end
    end
  end
end
