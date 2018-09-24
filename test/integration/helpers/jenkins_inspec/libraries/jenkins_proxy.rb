#
# Custom jenkins_proxy matcher
#

class JenkinsProxy < Inspec.resource(1)
  require 'rexml/document'

  name 'jenkins_proxy'

  attr_reader :id

  def initialize(id)
    @id = id
  end

  def exist?
    !xml.nil?
  end

  def name
    try { xml.elements['//name'].text }
  end

  def port
    try { xml.elements['//port'].text.to_i }
  end

  def noproxy
    try { xml.elements['//noProxyHost'].text.split("\n").map(&:strip) } || []
  end

  def to_s
    "Jenkins Proxy #{id}"
  end

  private

  def xml
    return @xml if @xml

    contents = inspec.backend.file('/var/lib/jenkins/proxy.xml').content
    @xml = REXML::Document.new(contents) if contents
  rescue Errno::ENOENT
    @xml = nil
  end

  def try
    yield
  rescue NoMethodError
    nil
  end
end
