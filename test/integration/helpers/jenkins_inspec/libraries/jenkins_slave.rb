#
# Custom jenkins_slave matcher
#

class JenkinsSlave < Inspec.resource(1)
  require 'json'
  require 'net/http'
  require 'rexml/document'

  name 'jenkins_slave'

  attr_reader :name

  def initialize(name)
    @name = name
  end

  def exist?
    !xml.nil?
  end

  def connected?
    json && !json[:offline]
  end

  def online?
    json && !json[:temporarilyOffline]
  end

  ############################################
  # Base Slave Attributes
  ############################################
  def description
    json && json[:description]
  end

  def remote_fs
    try { xml.elements['//remoteFS'].text }
  end

  def labels
    try { xml.elements['//label'].text.split(' ').map(&:strip) } || []
  end

  def usage_mode
    try { xml.elements['//mode'].text }.downcase
  end

  def availability
    # returns something like `hudson.slaves.RetentionStrategy$Always`
    retention_class = try { xml.elements['//retentionStrategy'].attributes['class'] }
    retention_class.split('$').last
  end

  def in_demand_delay
    try { xml.elements['//inDemandDelay'].text }.to_i
  end

  def idle_delay
    try { xml.elements['//idleDelay'].text }.to_i
  end

  def environment
    try do
      hash = {}
      key = nil

      REXML::XPath.each(xml, '//tree-map/string') do |str|
        if key
          hash[key] = str.text
          key = nil
        else
          key = str.text
        end
      end

      hash
    end
  end

  ############################################
  # SSH Slave Attributes
  ############################################
  def host
    try { xml.elements['//host'].text }
  end

  def port
    try { xml.elements['//port'].text.to_i }
  end

  def java_path
    try { xml.elements['//javaPath'].text }
  end

  def credentials_id
    credentials_id = try { xml.elements['//credentialsId'].text }
    credentials_xml = credentials_xml_for_id(credentials_id)
    try { credentials_xml.elements['id'].text }
  end

  def credentials_username
    credentials_id = try { xml.elements['//credentialsId'].text }
    credentials_xml = credentials_xml_for_id(credentials_id)
    try { credentials_xml.elements['username'].text }
  end

  def launch_timeout
    try { xml.elements['//launchTimeoutSeconds'].text.to_i }
  end

  def ssh_retries
    try { xml.elements['//maxNumRetries'].text.to_i }
  end

  def ssh_wait_retries
    try { xml.elements['//retryWaitTime'].text.to_i }
  end

  ############################################
  # Offline Attributes
  ############################################
  def offline_reason
    # offlineCauseReason has escaped spaces
    json && json[:offlineCauseReason].gsub('\\ ', ' ')
  end

  def to_s
    "Jenkins Slave #{name}"
  end

  private

  def xml
    return @xml if @xml

    config_url = "http://localhost:8080/computer/#{name}/config.xml"
    opts = {}
    worker = Inspec::Resources::Http::Worker::Remote.new(inspec, 'GET', config_url, opts)
    # response = Net::HTTP.get_response(URI.parse(config_url))

    @xml =
      if worker.status == 404
        nil
      # If authn is enabled fall back to reading main config from disk
      elsif worker.status == 403
        # attempt to read from dedicated slave xml file first

        config_path = "/var/lib/jenkins/nodes/#{name}/config.xml"
        contents = inspec.backend.file(config_path).content
        if contents
          REXML::Document.new(contents)
        else
          contents = inspec.backend.file('/var/lib/jenkins/config.xml').content
          config_xml = REXML::Document.new(contents)
          REXML::Document.new(config_xml.elements["//slave[name='#{name}']"].to_s)
        end

      else
        REXML::Document.new(worker.body)
      end
  end

  def json
    return @json if @json

    config_url = "http://localhost:8080/computer/#{name}/api/json?pretty=true"
    opts = {}
    worker = Inspec::Resources::Http::Worker::Remote.new(inspec, 'GET', config_url, opts)

    @json = if worker.status == 404
              nil
            else
              JSON.parse(worker.body, symbolize_names: true)
            end
  end

  def credentials_xml_for_id(credentials_id)
    contents = inspec.backend.file('/var/lib/jenkins/credentials.xml').content
    doc = REXML::Document.new(contents)
    REXML::XPath.first(doc, "//*[id/text() = '#{credentials_id}']/")
  rescue Errno::ENOENT
    nil
  end

  def try(&_block)
    yield
  rescue NoMethodError
    nil
  end
end
