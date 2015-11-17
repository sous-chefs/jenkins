#
# Custom jenkins_user matcher
#
module Serverspec
  module Type
    # rubocop:disable PredicateName
    class JenkinsPlugin < Base
      attr_reader :name

      def jenkins_plugin?
        !config.empty?
      end

      def enabled?
        !disabled?
      end

      def disabled?
        ::File.exist?(disabled_plugin)
      end

      def has_version?(version)
        version == config[:plugin_version]
      end

      private

      def disabled_plugin
        "/var/lib/jenkins/plugins/#{name}.jpi.disabled"
      end

      def config
        manifest = "/var/lib/jenkins/plugins/#{name}/META-INF/MANIFEST.MF"

        @config ||= Hash[*::File.readlines(manifest).map do |line|
          next if line.strip.empty?

          key, value = line.strip.split(' ', 2).map(&:strip)
          key = key.delete(':').tr('-', '_').downcase.to_sym
          next unless key && value
          [key, value]
        end.flatten.compact]
      rescue Errno::ENOENT
        @config = {}
      end
    end
  end
end
