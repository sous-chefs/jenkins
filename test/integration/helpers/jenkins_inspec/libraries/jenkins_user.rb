class JenkinsUser < Inspec.resource(1)
  require 'rexml/document'

  name 'jenkins_user'

  attr_reader :id

  def initialize(id)
    @id = id
  end

  def exist?
    !xml.nil?
  end

  def email
    try { xml.elements['//emailAddress'].text }
  end

  def full_name
    try { xml.elements['//fullName'].text }
  end

  def public_key
    try { xml.elements['//authorizedKeys'].text.split("\n").map(&:strip) } || []
  end

  def password_hash
    try { xml.elements['//passwordHash'].text }
  end

  def to_s
    "Jenkins User #{id}"
  end

  private

  def xml
    return @xml if defined?(@xml)

    direct_file = "/var/lib/jenkins/users/#{id}/config.xml"
    @xml = parse_user_xml(direct_file)
    return @xml if @xml

    user_mapping_raw = inspec.backend.file('/var/lib/jenkins/users/users.xml').content
    if user_mapping_raw && !user_mapping_raw.empty?
      user_mapping = REXML::Document.new(user_mapping_raw)
      folder = user_mapping.elements["//*[string/text() = '#{id}']/string[2]/text()"].to_s

      if folder && !folder.empty?
        @xml = parse_user_xml("/var/lib/jenkins/users/#{folder}/config.xml")
        return @xml if @xml
      end
    end

    user_config_paths = inspec.command('find /var/lib/jenkins/users -mindepth 2 -maxdepth 2 -name config.xml -print').stdout.lines.map(&:strip)

    @xml = user_config_paths.lazy.map { |path| parse_user_xml(path) }.find do |user_xml|
      user_xml && user_xml.elements['//id']&.text == id
    end
  rescue Errno::ENOENT
    @xml = nil
  end

  def parse_user_xml(path)
    contents = inspec.backend.file(path).content
    return if contents.nil? || contents.empty?

    REXML::Document.new(contents)
  rescue REXML::ParseException
    nil
  end

  def try(&_block)
    yield
  rescue NoMethodError
    nil
  end
end
