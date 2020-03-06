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

require 'test_helper'
require 'csv'

class WriteApiIntegrationTest < MiniTest::Test
  def setup
    WebMock.allow_net_connect!
  end

  def test_write_into_influx_db
    client = InfluxDB2::Client.new('http://localhost:9999', 'my-token',
                                   bucket: 'my-bucket',
                                   org: 'my-org',
                                   precision: InfluxDB2::WritePrecision::NANOSECOND,
                                   use_ssl: false)

    now = Time.now.utc

    measurement = 'h2o_' + now.to_i.to_s + now.nsec.to_s
    point = InfluxDB2::Point.new(name: measurement)
                            .add_tag('location', 'europe')
                            .add_field('level', 2)
                            .time(now, InfluxDB2::WritePrecision::NANOSECOND)

    client.create_write_api.write(data: point)

    csv = _query(measurement)

    refute_nil csv
    assert_equal measurement, csv[0]['_measurement']
    assert_equal 'europe', csv[0]['location']
    assert_equal '2', csv[0]['_value']
    assert_equal 'level', csv[0]['_field']
  end

  private

  def _query(measurement)
    query = { 'query': 'from(bucket: "my-bucket") |> range(start: -15m, stop: now()) '\
          "|> filter(fn: (r) => r._measurement == \"#{measurement}\")", 'type': 'flux' }

    uri = URI.parse('http://localhost:9999/api/v2/query?org=my-org')
    request = Net::HTTP::Post.new(uri.request_uri)
    request['Authorization'] = 'Token my-token'
    request[InfluxDB2::DefaultApi::HEADER_CONTENT_TYPE] = 'application/json'
    request.body = query.to_json

    http = Net::HTTP.new(uri.host, uri.port)
    begin
      response = http.request(request)

      CSV.parse(response.body, headers: true)
    ensure
      http.finish if http.started?
    end
  end
end
