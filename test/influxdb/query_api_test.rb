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

class QueryApiTest < MiniTest::Test
  def setup
    WebMock.disable_net_connect!
  end

  SUCCESS_DATA = '#datatype,string,long,dateTime:RFC3339,dateTime:RFC3339,dateTime:RFC3339,' \
    "long,string,string,string,string\n" \
    "#group,false,false,false,false,false,false,false,false,false,true\n" + "#default,_result,,,,,,,,,\n" \
    ",result,table,_start,_stop,_time,_value,_field,_measurement,host,region\n" \
    ",,0,1970-01-01T00:00:10Z,1970-01-01T00:00:20Z,1970-01-01T00:00:10Z,10,free,mem,A,west\n" \
    ",,0,1970-01-01T00:00:10Z,1970-01-01T00:00:20Z,1970-01-01T00:00:10Z,20,free,mem,B,west\n" \
    ",,0,1970-01-01T00:00:20Z,1970-01-01T00:00:30Z,1970-01-01T00:00:20Z,11,free,mem,A,west\n" \
    ',,0,1970-01-01T00:00:20Z,1970-01-01T00:00:30Z,1970-01-01T00:00:20Z,22,free,mem,B,west'

  def test_query_raw
    stub_request(:post, 'http://localhost:9999/api/v2/query?org=my-org')
      .to_return(body: SUCCESS_DATA)
    client = InfluxDB2::Client.new('http://localhost:9999', 'my-token',
                                   bucket: 'my-bucket',
                                   org: 'my-org',
                                   use_ssl: false)

    bucket = 'my-bucket'
    result = client.create_query_api.query_raw(query:
      'from(bucket:"' + bucket + '") |> range(start: 1970-01-01T00:00:00.000000001Z) |> last()')

    assert_equal result, SUCCESS_DATA
  end

  def test_query
    stub_request(:post, 'http://localhost:9999/api/v2/query?org=my-org')
      .to_return(body: SUCCESS_DATA)

    client = InfluxDB2::Client.new('http://localhost:9999', 'my-token',
                                   bucket: 'my-bucket',
                                   org: 'my-org',
                                   use_ssl: false)

    bucket = 'my-bucket'
    result = client.create_query_api.query(query:
      'from(bucket:"' + bucket + '") |> range(start: 1970-01-01T00:00:00.000000001Z) |> last()')

    assert_equal 1, result.length
    assert_equal 4, result[0].records.length

    record1 = result[0].records[0]

    assert_equal Time.parse('1970-01-01T00:00:10Z').to_datetime.rfc3339, record1.time
    assert_equal 'mem', record1.measurement
    assert_equal 10, record1.value
    assert_equal 'free', record1.field
  end

  def test_headers
    stub_request(:post, 'http://localhost:9999/api/v2/query?org=my-org')
      .to_return(body: SUCCESS_DATA)

    client = InfluxDB2::Client.new('http://localhost:9999', 'my-token',
                                   bucket: 'my-bucket',
                                   org: 'my-org',
                                   use_ssl: false)

    client.create_query_api
          .query(query: 'from(bucket:"my-bucket") |> range(start: 1970-01-01T00:00:00.000000001Z) |> last()')

    headers = {
      'Authorization' => 'Token my-token',
      'User-Agent' => "influxdb-client-ruby/#{InfluxDB2::VERSION}",
      'Content-Type' => 'application/json'
    }
    assert_requested(:post, 'http://localhost:9999/api/v2/query?org=my-org',
                     times: 1, headers: headers)
  end
end
