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

class WriteApiTest < MiniTest::Test
  def setup
    WebMock.disable_net_connect!
  end

  def test_redirect_same
    stub_request(:any, 'http://localhost:8086/api/v2/write?bucket=my-bucket&org=my-org&precision=ns')
      .to_return(status: 307, headers:
        { 'location' => 'http://localhost:8086' })
      .then.to_return(status: 204)
    stub_request(:any, 'http://localhost:8086/api/v2/write?bucket=my-bucket&org=my-org&precision=ns')
      .to_return(status: 204)

    client = InfluxDB2::Client.new('http://localhost:8086', 'my-token',
                                   bucket: 'my-bucket',
                                   org: 'my-org',
                                   precision: InfluxDB2::WritePrecision::NANOSECOND,
                                   use_ssl: false)

    client.create_write_api.write(data: 'h2o,location=west value=33i 15')

    headers = {
      'Authorization' => 'Token my-token',
      'User-Agent' => "influxdb-client-ruby/#{InfluxDB2::VERSION}",
      'Content-Type' => 'text/plain'
    }

    assert_requested(:post, 'http://localhost:8086/api/v2/write?bucket=my-bucket&org=my-org&precision=ns',
                     times: 1, body: 'h2o,location=west value=33i 15', headers: headers)
  end

  def test_redirect_301
    stub_request(:any, 'http://localhost:8086/api/v2/write?bucket=my-bucket&org=my-org&precision=ns')
      .to_return(status: 301, headers:
        { 'location' => 'http://localhost:9090/' })
      .then.to_return(status: 204)
    stub_request(:any, 'http://localhost:9090/api/v2/write?bucket=my-bucket&org=my-org&precision=ns')
      .to_return(status: 204)

    client = InfluxDB2::Client.new('http://localhost:8086', 'my-token',
                                   bucket: 'my-bucket',
                                   org: 'my-org',
                                   precision: InfluxDB2::WritePrecision::NANOSECOND,
                                   use_ssl: false)

    client.create_write_api.write(data: 'h2o,location=west value=33i 15')

    headers = {
      'Authorization' => 'Token my-token',
      'User-Agent' => "influxdb-client-ruby/#{InfluxDB2::VERSION}",
      'Content-Type' => 'text/plain'
    }

    assert_requested(:post, 'http://localhost:8086/api/v2/write?bucket=my-bucket&org=my-org&precision=ns',
                     times: 1, body: 'h2o,location=west value=33i 15', headers: headers)

    assert_not_requested(:post, 'http://localhost:9090/api/v2/write?bucket=my-bucket&org=my-org&precision=ns',
                         times: 1, body: 'h2o,location=west value=33i 15', headers: headers)

    assert_requested(:post, 'http://localhost:9090/api/v2/write?bucket=my-bucket&org=my-org&precision=ns',
                     times: 1, body: 'h2o,location=west value=33i 15')
  end

  def test_redirect_301_allow
    stub_request(:any, 'http://localhost:8086/api/v2/write?bucket=my-bucket&org=my-org&precision=ns')
      .to_return(status: 301, headers:
        { 'location' => 'http://localhost:9090/' })
      .then.to_return(status: 204)
    stub_request(:any, 'http://localhost:9090/api/v2/write?bucket=my-bucket&org=my-org&precision=ns')
      .to_return(status: 204)

    client = InfluxDB2::Client.new('http://localhost:8086', 'my-token',
                                   bucket: 'my-bucket',
                                   org: 'my-org',
                                   precision: InfluxDB2::WritePrecision::NANOSECOND,
                                   use_ssl: false,
                                   redirect_forward_authorization: true)

    client.create_write_api.write(data: 'h2o,location=west value=33i 15')

    headers = {
      'Authorization' => 'Token my-token',
      'User-Agent' => "influxdb-client-ruby/#{InfluxDB2::VERSION}",
      'Content-Type' => 'text/plain'
    }

    assert_requested(:post, 'http://localhost:8086/api/v2/write?bucket=my-bucket&org=my-org&precision=ns',
                     times: 1, body: 'h2o,location=west value=33i 15', headers: headers)

    assert_requested(:post, 'http://localhost:9090/api/v2/write?bucket=my-bucket&org=my-org&precision=ns',
                     times: 1, body: 'h2o,location=west value=33i 15', headers: headers)
  end

  def test_redirect_different_path
    stub_request(:any, 'http://localhost:8086/api/v2/write?bucket=my-bucket&org=my-org&precision=ns')
      .to_return(status: 301, headers:
        { 'location' => 'http://localhost:8086/influxdb/' })
      .then.to_return(status: 204)
    stub_request(:any, 'http://localhost:8086/influxdb/api/v2/write?bucket=my-bucket&org=my-org&precision=ns')
      .to_return(status: 204)

    client = InfluxDB2::Client.new('http://localhost:8086', 'my-token',
                                   bucket: 'my-bucket',
                                   org: 'my-org',
                                   precision: InfluxDB2::WritePrecision::NANOSECOND,
                                   use_ssl: false,
                                   redirect_forward_authorization: true)

    client.create_write_api.write(data: 'h2o,location=west value=33i 15')

    headers = {
      'Authorization' => 'Token my-token',
      'User-Agent' => "influxdb-client-ruby/#{InfluxDB2::VERSION}",
      'Content-Type' => 'text/plain'
    }

    assert_requested(:post, 'http://localhost:8086/api/v2/write?bucket=my-bucket&org=my-org&precision=ns',
                     times: 1, body: 'h2o,location=west value=33i 15', headers: headers)

    assert_requested(:post, 'http://localhost:8086/influxdb/api/v2/write?bucket=my-bucket&org=my-org&precision=ns',
                     times: 1, body: 'h2o,location=west value=33i 15', headers: headers)
  end
end
