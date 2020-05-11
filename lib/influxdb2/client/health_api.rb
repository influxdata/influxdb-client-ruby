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
  # The client of the InfluxDB 2.0 that implement Health HTTP API endpoint.
  #
  class HealthApi < DefaultApi
    # @param [Hash] options The options to be used by the client.
    def initialize(options:)
      super(options: options)
    end

    # Get the health of an instance.
    #
    # @return [HealthCheck]
    def health
      uri = _parse_uri('/health')
      body = _get(uri).body
      data = JSON.parse("[#{body}]", symbolize_names: true)[0]
      HealthCheck.new.tap do |model|
        model.build_from_hash data
      end
    rescue StandardError => e
      HealthCheck.new.tap do |model|
        model.name = 'influxdb'
        model.status = 'fail'
        model.message = e.message
      end
    end
  end
end
