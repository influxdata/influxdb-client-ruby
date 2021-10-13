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
require 'net/http'

module InfluxDB2
  # The client is the entry point to HTTP API defined
  # in https://github.com/influxdata/influxdb/blob/master/http/swagger.yml.
  class Client
    # @return [ Hash ] options The configuration options.
    attr_reader :options

    # Instantiate a new InfluxDB client.
    #
    # @example Instantiate a client.
    #   InfluxDBClient::Client.new(url: 'https://localhost:8086', token: 'my-token')
    #
    # @param [Hash] options The options to be used by the client.
    # @param [String] url InfluxDB URL to connect to (ex. https://localhost:8086).
    # @param [String] token Access Token used for authenticating/authorizing the InfluxDB request sent by client.
    #
    # @option options [String] :bucket the default destination bucket for writes
    # @option options [String] :org the default organization bucket for writes
    # @option options [WritePrecision] :precision the default precision for the unix timestamps within
    # @option options [Integer] :open_timeout Number of seconds to wait for the connection to open
    # @option options [Integer] :write_timeout Number of seconds to wait for one block of data to be written
    # @option options [Integer] :read_timeout Number of seconds to wait for one block of data to be read
    # @option options [Integer] :max_redirect_count Maximal number of followed HTTP redirects
    # @option options [bool] :redirect_forward_authorization Pass Authorization header to different domain
    #   during HTTP redirect.
    # @option options [bool] :use_ssl Turn on/off SSL for HTTP communication
    # @option options [Integer] :verify_mode Sets the flags for the certification verification
    #   at beginning of SSL/TLS session. Could be one of `OpenSSL::SSL::VERIFY_NONE` or `OpenSSL::SSL::VERIFY_PEER`.
    #   For more info see - https://docs.ruby-lang.org/en/3.0.0/Net/HTTP.html#verify_mode.
    # @option options [Logger] :logger Logger used for logging. Disable logging by set to false.
    # @option options [Hash] :tags Default tags which will be added to each point written by api.
    #   the body line-protocol
    def initialize(url, token, options = nil)
      @auto_closeable = []
      @options = options ? options.dup : {}
      @options[:url] = url if url.is_a? String
      @options[:token] = token if token.is_a? String
      @options[:logger] = @options[:logger].nil? ? DefaultApi.create_logger : @options[:logger]
      @closed = false

      at_exit { close! }
    end

    # Write time series data into InfluxDB thought WriteApi.
    #
    # @return [WriteApi] New instance of WriteApi.
    def create_write_api(write_options: InfluxDB2::SYNCHRONOUS, point_settings: InfluxDB2::DEFAULT_POINT_SETTINGS)
      write_api = WriteApi.new(options: @options, write_options: write_options, point_settings: point_settings)
      @auto_closeable.push(write_api)
      write_api
    end

    # Get the Query client.
    #
    # @return [QueryApi] New instance of QueryApi.
    def create_query_api
      QueryApi.new(options: @options)
    end

    # Get the Delete API to delete time series data from InfluxDB.
    #
    # @return [DeleteApi] New instance of DeleteApi.
    def create_delete_api
      DeleteApi.new(options: @options)
    end

    # Get the health of an instance.
    #
    # @deprecated Use `ping` instead
    # @return [HealthCheck]
    def health
      HealthApi.new(options: @options).health
    end

    # Checks the status of InfluxDB instance and version of InfluxDB.
    #
    # @deprecated Use `ping` instead
    # @return [Ping]
    def ping
      PingApi.new(options: @options).ping
    end

    # Close all connections into InfluxDB 2.
    #
    # @return [ true ] Always true.
    def close!
      @closed = true
      @auto_closeable.each(&:close!)
      true
    end
  end
end
