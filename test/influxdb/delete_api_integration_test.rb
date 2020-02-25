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

class DeleteApiIntegrationTest < MiniTest::Test
  def setup
    WebMock.allow_net_connect!

    @client = InfluxDB2::Client.new('http://localhost:9999', 'my-token',
                                    bucket: 'my-bucket',
                                    org: 'my-org',
                                    precision: InfluxDB2::WritePrecision::NANOSECOND,
                                    use_ssl: false)

    now = Time.now.utc
    @measurement = 'h2o_delete_' + now.to_i.to_s + +now.nsec.to_s

    data = [InfluxDB2::Point.new(name: @measurement)
                            .add_tag('location', 'europe')
                            .add_field('level', 2)
                            .time(Time.utc(2015, 10, 15, 8, 20, 15), InfluxDB2::WritePrecision::MILLISECOND),
            InfluxDB2::Point.new(name: @measurement)
                            .add_tag('location', 'us')
                            .add_field('level', 2)
                            .time(Time.utc(2016, 10, 15, 8, 20, 15), InfluxDB2::WritePrecision::MILLISECOND),
            InfluxDB2::Point.new(name: @measurement)
                            .add_tag('location', 'india')
                            .add_field('level', 2)
                            .time(Time.utc(2017, 10, 15, 8, 20, 15), InfluxDB2::WritePrecision::MILLISECOND),
            InfluxDB2::Point.new(name: @measurement)
                            .add_tag('location', 'europe')
                            .add_field('level', 2)
                            .time(Time.utc(2018, 10, 15, 8, 20, 15), InfluxDB2::WritePrecision::MILLISECOND)]

    @client.create_write_api.write(data: data, precision: InfluxDB2::WritePrecision::MILLISECOND)

    assert_equal 4, _query_count
  end

  def test_delete
    @client.create_delete_api.delete(Time.utc(2015, 10, 16, 8, 20, 15), Time.utc(2020, 10, 16, 8, 20, 15),
                                     predicate: 'location="europe"')

    assert_equal 3, _query_count
  end

  def test_delete_without_predicate
    @client.create_delete_api.delete(Time.utc(2016, 10, 15, 7, 20, 15), Time.utc(2018, 10, 14, 8, 20, 15))

    assert_equal 2, _query_count
  end

  def test_delete_all
    @client.create_delete_api.delete(Time.utc(2010, 10, 15, 7, 20, 15), Time.utc(2020, 10, 14, 8, 20, 15))

    assert_equal 0, _query_count
  end

  def test_delete_without_interval
    error = assert_raises InfluxDB2::InfluxError do
      @client.create_delete_api.delete(nil, nil)
    end

    assert error.message.include?('invalid request'),
           "Error message: '#{error.message}' doesn't contains 'invalid request'"
  end

  private

  def _query_count
    query = 'from(bucket: "my-bucket") |> range(start: 0) |> ' \
           "filter(fn: (r) => r._measurement == \"#{@measurement}\") " \
           '|> drop(columns: ["location"]) |> count()'

    table = @client.create_query_api.query(query: InfluxDB2::Query.new(query: query,
                                                                       dialect: InfluxDB2::QueryApi::DEFAULT_DIALECT,
                                                                       type: nil))[0]
    return 0 if table.nil?

    table.records[0].value
  end
end
