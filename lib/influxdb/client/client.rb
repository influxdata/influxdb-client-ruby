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

module InfluxDB
  # The client is the entry point to HTTP API defined
  # in https://github.com/influxdata/influxdb/blob/master/http/swagger.yml.
  class Client
    # @return [ Hash ] options The configuration options.
    attr_reader :options

    # Instantiate a new InfluxDB client.
    #
    # @example Instantiate a client.
    #   InfluxDBClient::Client.new(url: 'http://localhost:9999', token: 'my-token')
    #
    # @param [String] url InfluxDB server API url (ex. http://localhost:9999).
    # @param [String] token authentication token
    def initialize(options = nil, url:, token:)
      @options = options ? options.dup : {}
      @options[:url] = url if url.is_a? String
      @options[:token] = token if token.is_a? String
      @closed = false

      at_exit { close }
    end

    # Write time series data into InfluxDB thought WriteApi.
    #
    # @return [WriteApi] New instance of WriteApi.
    def create_write_api
      WriteApi.new
    end

    # Close all connections into InfluxDB 2.
    #
    # @return [ true ] Always true.
    def close
      @closed = true
      true
    end
  end
end
