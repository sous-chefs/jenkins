#
# Custom jenkins_user matcher
#

class JenkinsBuild < Inspec.resource(1)
  require 'json'
  require 'net/http'

  name 'jenkins_build'

  attr_reader :build_name
  attr_reader :build_number

  def initialize(name, number)
    @build_name = name
    @build_number = number =~ /\A\d+\Z/ ? number : resolve_build_tag_to_number(number)
  end

  def exist?
    !json.nil?
  end

  def parameters
    if (params = json[:actions].find { |a| a.key?(:parameters) })
      # Transform:
      #
      #  {:parameters=>
      #    [{:name=>"STRING_PARAM", :value=>"meeseeks"},
      #     {:name=>"BOOLEAN_PARAM", :value=>true}]}
      #
      # into a nice param_name => param_value Hash
      #
      Hash[params[:parameters].map { |p| [p[:name], p[:value]] }]
    else
      {}
    end
  end

  def to_s
    "Jenkins Build #{build_name} ##{build_number}"
  end

  private

  def json
    return @json if @json

    build_result_url = "http://localhost:8080/job/#{build_name}/#{build_number}/api/json?pretty=true"
    opts = {}
    worker = Inspec::Resources::Http::Worker::Remote.new(inspec, 'GET', build_result_url, opts)

    @json = if worker.status == 404
              nil
            else
              JSON.parse(worker.body, symbolize_names: true)
            end
  end

  def resolve_build_tag_to_number(build_tag)
    build_url = "http://localhost:8080/job/#{build_name}/api/json?pretty=true"
    opts = {}
    worker = Inspec::Resources::Http::Worker::Remote.new(inspec, 'GET', build_url, opts)

    build_json = JSON.parse(worker.body, symbolize_names: true)
    build_json[build_tag.to_sym][:number]
  end
end
