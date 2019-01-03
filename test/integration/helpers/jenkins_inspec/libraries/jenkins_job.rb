#
# Custom jenkins_user matcher
#

class JenkinsJob < Inspec.resource(1)
  require 'rexml/document'

  name 'jenkins_job'

  attr_reader :name

  def initialize(name)
    @name = name
  end

  def exist?
    !xml.nil?
  end

  def disabled?
    (try { xml.elements['//disabled'].text.to_s == 'true' }) != (nil || false)
  end

  def enabled?
    !disabled?
  end

  def command
    try { xml.elements['//command'].text }.strip
  end

  def plugin
    try { xml.root.attributes['plugin'] }
  end

  def to_s
    "Jenkins Job #{name}"
  end

  private

  def xml
    return @xml if @xml
    job_file = "/var/lib/jenkins/jobs/#{name}/config.xml"
    return unless inspec.backend.file(job_file).file?

    contents = inspec.backend.file(job_file).content
    @xml = REXML::Document.new(contents)
  rescue Errno::ENOENT
    @xml = nil
  end

  def try(&_block)
    yield
  rescue NoMethodError
    nil
  end
end
