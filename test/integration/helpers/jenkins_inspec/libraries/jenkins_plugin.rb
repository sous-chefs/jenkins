#
# Custom jenkins_user matcher
#

class JenkinsPlugin < Inspec.resource(1)
  attr_reader :name

  name 'jenkins_plugin'

  def initialize(name)
    @name = name
  end

  def exist?
    !!(config && !config.empty?)
  end

  def enabled?
    !disabled?
  end

  def disabled?
    inspec.backend.file(disabled_plugin).file?
  end

  def version
    config[:plugin_version]
  end

  def to_s
    "Jenkins Plugin #{name}"
  end

  private

  def disabled_plugin
    "/var/lib/jenkins/plugins/#{name}.jpi.disabled"
  end

  def config
    manifest = "/var/lib/jenkins/plugins/#{name}/META-INF/MANIFEST.MF"
    f = inspec.backend.file(manifest)
    return unless f.file?

    @config ||= Hash[*f.content.lines.map do |line|
      next unless line
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
