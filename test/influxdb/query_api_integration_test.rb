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

class QueryApiIntegrationTest < MiniTest::Test
  def setup
    WebMock.allow_net_connect!

    @client = InfluxDB2::Client.new('http://localhost:8086', 'my-token',
                                    bucket: 'my-bucket',
                                    org: 'my-org',
                                    precision: InfluxDB2::WritePrecision::NANOSECOND,
                                    use_ssl: false)
  end

  def test_query
    now = Time.now.utc
    measurement = 'h2o_query_' + now.to_i.to_s + now.nsec.to_s

    @client.create_write_api.write(data: InfluxDB2::Point.new(name: measurement)
                                                         .add_tag('location', 'europe')
                                                         .add_field('level', 2)
                                                         .time(now, InfluxDB2::WritePrecision::NANOSECOND))

    result = @client.create_query_api.query(query: 'from(bucket: "my-bucket") |> range(start: -1m, stop: now()) '\
          "|> filter(fn: (r) => r._measurement == \"#{measurement}\")")

    assert_equal 1, result.size

    records = result[0].records
    assert_equal 1, records.size

    record = records[0]

    assert_equal measurement, record.measurement
    assert_equal 'europe', record.values['location']
    assert_equal 2, record.value
    assert_equal 'level', record.field
  end
end
