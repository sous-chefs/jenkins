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
    return @xml if @xml

    user_file = inspec.backend.file("/var/lib/jenkins/users/#{id}/config.xml")

    if user_file.file?
      @xml = REXML::Document.new(user_file.contents)
    else
      # Jenkins has a new way to store user config files
      # We need to read the mapping file to find the directory for the user config
      user_mapping_raw = inspec.backend.file('/var/lib/jenkins/users/users.xml').content
      return unless user_mapping_raw

      user_mapping = REXML::Document.new(user_mapping_raw)
      # its in a key pair configuration, user id => folder name
      folder = user_mapping.elements["//*[string/text() = '#{id}']/string[2]/text()"].to_s

      return unless folder

      file_path = "/var/lib/jenkins/users/#{folder}/config.xml"
      contents = inspec.backend.file(file_path).content

      return unless contents
      @xml = REXML::Document.new(contents)
    end
  rescue Errno::ENOENT
    @xml = nil
  end

  def try(&_block)
    yield
  rescue NoMethodError
    nil
  end
end
