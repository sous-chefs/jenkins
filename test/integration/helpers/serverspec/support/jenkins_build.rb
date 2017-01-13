#
# Custom jenkins_user matcher
#
module Serverspec
  module Type
    class JenkinsBuild < Base
      require 'json'
      require 'net/http'

      attr_reader :build_name
      attr_reader :build_number

      def initialize(name, number)
        @build_name = name
        @build_number = number =~ /\A\d+\Z/ ? number : resolve_build_tag_to_number(number)
        super("#{name} ##{number}")
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

      private

      def json
        return @json if @json

        build_result_url = "http://localhost:8080/job/#{build_name}/#{build_number}/api/json?pretty=true"
        response = Net::HTTP.get_response(URI.parse(build_result_url))

        @json = if response.is_a? Net::HTTPNotFound
                  nil
                else
                  JSON.parse(response.body, symbolize_names: true)
                end
      end

      def resolve_build_tag_to_number(build_tag)
        build_url = "http://localhost:8080/job/#{build_name}/api/json?pretty=true"
        response = Net::HTTP.get_response(URI.parse(build_url))
        build_json = JSON.parse(response.body, symbolize_names: true)
        build_json[build_tag.to_sym][:number]
      end
    end
  end
end
