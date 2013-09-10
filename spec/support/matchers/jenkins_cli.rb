module ChefSpec
  module Matchers
    RSpec::Matchers.define :run_jenkins_cli do |name|
      @name = name

      match do |chef_run|
        resource && expected_attributes?(resource)
      end

      chain(:with) do |attributes|
        @attributes = attributes
      end

      failure_message_for_should do |actual|
        message = "No jenkins_cli named '#{@name}' found"

        unless @attributes.empty?
          message << " with:\n\n#{JSON.pretty_generate(@attributes)}"
          message << "\n\nattributes were:\n\n"
          message << JSON.pretty_generate(resource_methods)
        else
          message << "\n\nother resources were:\n\n"
          message << other_resources.map(&:name).join("\n")
        end

        message
      end

      def expected_attributes?(resource)
        (@attributes ||= {}).all? { |k, v| v === resource.send(k) }
      end

      def other_resources
        @chef_run.resources.select { |r| resource_type(r) == 'jenkins_cli' }
      end

      def resource
        @resource ||= chef_run.resources.find do |resource|
          resource_type(resource) == 'jenkins_cli' &&
          Array(resource.action).include?(:run) &&
          resource.name === @name
        end
      end

      def resource_methods
        return {} unless resource

        [
          :url,
          :home,
          :command,
          :timeout,
          :block,
          :jvm_options,
          :username,
          :password,
          :password_file,
          :key_file
        ].sort.inject({}) do |hash, m|
          unless (result = resource.send(m)).nil?
            hash[m] = resource.send(m)
          end

          hash
        end
      end
    end
  end
end
