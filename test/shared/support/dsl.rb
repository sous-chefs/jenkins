module RSpec
  module Core
    module DSL
      def jenkins_user(id)
        Serverspec::Type::JenkinsUser.new(id)
      end
    end
  end
end
