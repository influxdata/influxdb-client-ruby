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

class QueryApiStreamTest < MiniTest::Test
  def setup
    WebMock.allow_net_connect!

    @client = InfluxDB2::Client.new('http://localhost:9999', 'my-token',
                                    bucket: 'my-bucket',
                                    org: 'my-org',
                                    precision: InfluxDB2::WritePrecision::NANOSECOND,
                                    use_ssl: false)
    @now = Time.now.utc
  end

  def test_query_stream
    measurement = 'h2o_query_stream' + @now.to_i.to_s + @now.nsec.to_s
    _write(10, measurement: measurement)

    query = 'from(bucket: "my-bucket") |> range(start: -1m, stop: now()) ' \
      "|> filter(fn: (r) => r._measurement == \"#{measurement}\")"

    count = 0
    @client.create_query_api.query_stream(query: query).each do |record|
      count += 1
      assert_equal measurement, record.measurement
      assert_equal 'europe', record.values['location']
      assert_equal count, record.value
      assert_equal 'level', record.field
    end

    assert_equal 10, count
  end

  def test_query_stream_break
    measurement = 'h2o_query_stream_break' + @now.to_i.to_s + @now.nsec.to_s
    _write(20, measurement: measurement)

    query = 'from(bucket: "my-bucket") |> range(start: -1m, stop: now()) ' \
      "|> filter(fn: (r) => r._measurement == \"#{measurement}\")"

    records = []

    parser = @client.create_query_api.query_stream(query: query)

    assert_equal false, parser.closed

    count = 0
    parser.each do |record|
      records.push(record)
      count += 1

      break if count >= 5
    end

    assert_equal 5, records.size
    assert_equal true, parser.closed

    # record 1
    record = records[0]
    assert_equal measurement, record.measurement
    assert_equal 'europe', record.values['location']
    assert_equal 1, record.value
    assert_equal 'level', record.field
  end

  private

  def _write(values, measurement:)
    write_api = @client.create_write_api

    (1..values).each do |value|
      write_api.write(data: InfluxDB2::Point.new(name: measurement)
                                 .add_tag('location', 'europe')
                                 .add_field('level', value)
                                 .time(@now - values + value, InfluxDB2::WritePrecision::NANOSECOND))
    end
  end
end
