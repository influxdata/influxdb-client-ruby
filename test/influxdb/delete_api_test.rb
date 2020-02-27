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

class DeleteApiTest < MiniTest::Test
  def setup
    WebMock.disable_net_connect!
  end

  def test_delete
    stub_request(:any, 'http://localhost:9999/api/v2/delete?bucket=my-bucket&org=my-org')
      .to_return(status: 204)
    client = InfluxDB2::Client.new('http://localhost:9999', 'my-token',
                                   bucket: 'my-bucket',
                                   org: 'my-org',
                                   precision: InfluxDB2::WritePrecision::NANOSECOND,
                                   use_ssl: false)

    client.create_delete_api.delete(Time.utc(2019, 10, 15, 8, 20, 15), Time.utc(2019, 11, 15, 8, 20, 15),
                                    predicate: 'key1="value1" AND key2="value"', bucket: 'my-bucket', org: 'my-org')

    body = '{"start":"2019-10-15T08:20:15+00:00","stop":"2019-11-15T08:20:15+00:00","predicate":"key1=\"value1\" ' \
           'AND key2=\"value\""}'

    assert_requested(:post, 'http://localhost:9999/api/v2/delete?bucket=my-bucket&org=my-org', times: 1, body: body)
  end

  def test_delete_time_as_date_time
    stub_request(:any, 'http://localhost:9999/api/v2/delete?bucket=my-bucket&org=my-org')
      .to_return(status: 204)
    client = InfluxDB2::Client.new('http://localhost:9999', 'my-token',
                                   bucket: 'my-bucket',
                                   org: 'my-org',
                                   precision: InfluxDB2::WritePrecision::NANOSECOND,
                                   use_ssl: false)

    client.create_delete_api.delete(DateTime.rfc3339('2019-02-03T04:05:06+07:00'),
                                    DateTime.rfc3339('2019-03-03T04:05:06+07:00'),
                                    predicate: 'key1="value1" AND key2="value"', bucket: 'my-bucket', org: 'my-org')

    body = '{"start":"2019-02-03T04:05:06+07:00","stop":"2019-03-03T04:05:06+07:00","predicate":"key1=\"value1\" ' \
           'AND key2=\"value\""}'

    assert_requested(:post, 'http://localhost:9999/api/v2/delete?bucket=my-bucket&org=my-org', times: 1, body: body)
  end

  def test_delete_time_as_string
    stub_request(:any, 'http://localhost:9999/api/v2/delete?bucket=my-bucket&org=my-org')
      .to_return(status: 204)
    client = InfluxDB2::Client.new('http://localhost:9999', 'my-token',
                                   bucket: 'my-bucket',
                                   org: 'my-org',
                                   precision: InfluxDB2::WritePrecision::NANOSECOND,
                                   use_ssl: false)

    client.create_delete_api.delete('2019-02-03T04:05:06+07:00',  '2019-04-03T04:05:06+07:00',
                                    predicate: 'key1="value1" AND key2="value"', bucket: 'my-bucket', org: 'my-org')

    body = '{"start":"2019-02-03T04:05:06+07:00","stop":"2019-04-03T04:05:06+07:00","predicate":"key1=\"value1\" ' \
           'AND key2=\"value\""}'

    assert_requested(:post, 'http://localhost:9999/api/v2/delete?bucket=my-bucket&org=my-org', times: 1, body: body)
  end

  def test_without_predicate
    stub_request(:any, 'http://localhost:9999/api/v2/delete?bucket=my-bucket&org=my-org')
      .to_return(status: 204)
    client = InfluxDB2::Client.new('http://localhost:9999', 'my-token',
                                   bucket: 'my-bucket',
                                   org: 'my-org',
                                   precision: InfluxDB2::WritePrecision::NANOSECOND,
                                   use_ssl: false)

    client.create_delete_api.delete('2019-02-03T04:05:06+07:00', '2019-04-03T04:05:06+07:00',
                                    bucket: 'my-bucket', org: 'my-org')

    body = '{"start":"2019-02-03T04:05:06+07:00","stop":"2019-04-03T04:05:06+07:00"}'

    assert_requested(:post, 'http://localhost:9999/api/v2/delete?bucket=my-bucket&org=my-org', times: 1, body: body)
  end

  def test_user_agent_header
    stub_request(:any, 'http://localhost:9999/api/v2/delete?bucket=my-bucket&org=my-org')
      .to_return(status: 204)
    client = InfluxDB2::Client.new('http://localhost:9999', 'my-token',
                                   bucket: 'my-bucket',
                                   org: 'my-org',
                                   precision: InfluxDB2::WritePrecision::NANOSECOND,
                                   use_ssl: false)

    client.create_delete_api.delete('2019-02-03T04:05:06+07:00', '2019-04-03T04:05:06+07:00',
                                    bucket: 'my-bucket', org: 'my-org')

    body = '{"start":"2019-02-03T04:05:06+07:00","stop":"2019-04-03T04:05:06+07:00"}'
    headers = {
      'Authorization' => 'Token my-token',
      'User-Agent' => "influxdb-client-ruby/#{InfluxDB2::VERSION}"
    }
    assert_requested(:post, 'http://localhost:9999/api/v2/delete?bucket=my-bucket&org=my-org',
                     times: 1, body: body, headers: headers)
  end
end
