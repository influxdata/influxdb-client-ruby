# The MIT License
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
require_relative 'models/dialect'
require_relative 'models/query'
require_relative 'flux_csv_parser'
require 'json'

module InfluxDB2
  # The client of the InfluxDB 2.x that implement Query HTTP API endpoint.
  #
  class QueryApi < DefaultApi
    DEFAULT_DIALECT = InfluxDB2::Dialect.new(header: true, delimiter: ',', comment_prefix: '#',
                                             annotations: %w[datatype group default])

    # @param [Hash] options The options to be used by the client.
    def initialize(options:)
      super(options: options)
    end

    # @param [Object] query the flux query to execute. The data could be represent by [String], [Query]
    # @param [String] org specifies the source organization
    # @param [Enumerable] params represent key/value pairs parameters to be injected into query
    # @return [String] result of query
    def query_raw(query: nil, org: nil, dialect: DEFAULT_DIALECT, params: nil)
      _post_query(query: query, org: org, dialect: dialect, params: params).read_body
    end

    # @param [Object] query the flux query to execute. The data could be represent by [String], [Query]
    # @param [String] org specifies the source organization
    # @param [Enumerable] params represent key/value pairs parameters to be injected into query
    # @return [Array] list of FluxTables which are matched the query
    def query(query: nil, org: nil, dialect: DEFAULT_DIALECT, params: nil)
      response = query_raw(query: query, org: org, dialect: dialect, params: params)
      parser = InfluxDB2::FluxCsvParser.new(response)

      parser.parse
      parser.tables
    end

    # @param [Object] query the flux query to execute. The data could be represent by [String], [Query]
    # @param [String] org specifies the source organization
    # @param [Enumerable] params represent key/value pairs parameters to be injected into query
    # @return stream of Flux Records
    def query_stream(query: nil, org: nil, dialect: DEFAULT_DIALECT, params: nil)
      response = _post_query(query: query, org: org, dialect: dialect, params: params)

      InfluxDB2::FluxCsvParser.new(response, stream: true)
    end

    private

    def _post_query(query: nil, org: nil, dialect: DEFAULT_DIALECT, params: nil)
      org_param = org || @options[:org]
      _check('org', org_param)

      payload = _generate_payload(query: query, dialect: dialect, params: params)
      return nil if payload.nil?

      uri = _parse_uri('/api/v2/query')
      uri.query = URI.encode_www_form(org: org_param)

      _request_json(payload.to_body.to_json, uri)
    end

    def _generate_payload(query: nil, dialect: nil, params: nil)
      if query.nil?
        nil
      elsif query.is_a?(Query)
        query.params = params unless params.nil?
        query
      elsif query.is_a?(String)
        if query.empty?
          nil
        else
          Query.new(query: query, dialect: dialect, type: nil, params: params)
        end
      end
    end
  end
end
