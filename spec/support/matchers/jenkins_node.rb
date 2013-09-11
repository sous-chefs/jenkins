module ChefSpec
  module Matchers
    RSpec::Matchers.define :create_jenkins_node do |name|
      @name = name

      match do |chef_run|
        resource && expected_attributes?(resource)
      end

      chain(:with) do |attributes|
        @attributes = attributes
      end

      failure_message_for_should do |actual|
        message = "No jenkins_node named '#{@name}' found"

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
        @chef_run.resources.select { |r| resource_type(r) == 'jenkins_node' }
      end

      def resource
        @resource ||= chef_run.resources.find do |resource|
          resource_type(resource) == 'jenkins_node' &&
          Array(resource.action).include?(:create) &&
          resource.name === @name
        end
      end

      def resource_methods
        return {} unless resource

        [
          :description,
          :remote_fs,
          :executors,
          :mode,
          :labels,
          :launcher,
          :availability,
          :in_demand_delay,
          :idle_delay,
          :env,
          :command,
          :host,
          :port,
          :username,
          :password,
          :private_key,
          :jvm_options
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
