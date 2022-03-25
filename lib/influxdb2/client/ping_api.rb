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
require_relative 'models/health_check'

module InfluxDB2
  # The client of the InfluxDB 2.x that implement Ping HTTP API endpoint.
  #
  class PingApi < DefaultApi
    # @param [Hash] options The options to be used by the client.
    def initialize(options:)
      super(options: options)
    end

    # Checks the status of InfluxDB instance and version of InfluxDB.
    #
    # @return [Ping]
    def ping
      uri = _parse_uri('/ping')
      headers = _get(uri)
      Ping.new.tap do |model|
        model.status = 'ok'
        model.build = headers['X-Influxdb-Build']
        model.version = headers['X-Influxdb-Version']
        model.message = 'ready for queries and writes'
      end
    rescue StandardError => e
      Ping.new.tap do |model|
        model.status = 'fail'
        model.message = e.message
      end
    end
  end

  # The status of InfluxDB instance and version of InfluxDB.
  class Ping
    # The type of InfluxDB build.
    attr_accessor :build

    # The version of InfluxDB.
    attr_accessor :version

    # The status of InfluxDB.
    attr_accessor :status

    # The error message.
    attr_accessor :message
  end
end
