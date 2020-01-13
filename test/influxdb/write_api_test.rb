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

  def test_required_arguments
    client = InfluxDB2::Client.new('http://localhost:9999', 'my-token')
    write_api = client.create_write_api

    # precision
    assert_raises ArgumentError do
      write_api.write(data: {}, bucket: 'my-bucket', org: 'my-org')
    end
    # bucket
    assert_raises ArgumentError do
      write_api.write(data: {}, org: 'my-org', precision: InfluxDB2::WritePrecision::NANOSECOND)
    end
    # org
    assert_raises ArgumentError do
      write_api.write(data: {}, bucket: 'my-bucket', precision: InfluxDB2::WritePrecision::NANOSECOND)
    end
  end

  def test_default_arguments_
    client = InfluxDB2::Client.new('http://localhost:9999', 'my-token',
                                   bucket: 'my-bucket',
                                   org: 'my-org',
                                   precision: InfluxDB2::WritePrecision::NANOSECOND)
    write_api = client.create_write_api

    # without argument errors
    write_api.write(data: {})
  end

  def test_write_line_protocol
    stub_request(:any, 'http://localhost:9999/api/v2/write?bucket=my-bucket&org=my-org&precision=ns')
      .to_return(status: 204)
    client = InfluxDB2::Client.new('http://localhost:9999', 'my-token',
                                   bucket: 'my-bucket',
                                   org: 'my-org',
                                   precision: InfluxDB2::WritePrecision::NANOSECOND,
                                   use_ssl: false)

    client.create_write_api.write(data: 'h2o,location=west value=33i 15')

    assert_requested(:post, 'http://localhost:9999/api/v2/write?bucket=my-bucket&org=my-org&precision=ns',
                     times: 1, body: 'h2o,location=west value=33i 15')
  end

  def test_write_point
    stub_request(:any, 'http://localhost:9999/api/v2/write?bucket=my-bucket&org=my-org&precision=ns')
      .to_return(status: 204)
    client = InfluxDB2::Client.new('http://localhost:9999', 'my-token',
                                   bucket: 'my-bucket',
                                   org: 'my-org',
                                   precision: InfluxDB2::WritePrecision::NANOSECOND,
                                   use_ssl: false)

    client.create_write_api.write(data: InfluxDB2::Point.new(name: 'h2o')
                                            .add_tag('location', 'europe')
                                            .add_field('level', 2))

    assert_requested(:post, 'http://localhost:9999/api/v2/write?bucket=my-bucket&org=my-org&precision=ns',
                     times: 1, body: 'h2o,location=europe level=2i')
  end

  def test_write_hash
    stub_request(:any, 'http://localhost:9999/api/v2/write?bucket=my-bucket&org=my-org&precision=ns')
      .to_return(status: 204)
    client = InfluxDB2::Client.new('http://localhost:9999', 'my-token',
                                   bucket: 'my-bucket',
                                   org: 'my-org',
                                   precision: InfluxDB2::WritePrecision::NANOSECOND,
                                   use_ssl: false)

    client.create_write_api.write(data: { name: 'h2o',
                                          tags: { host: 'aws', region: 'us' },
                                          fields: { level: 5, saturation: '99%' }, time: 123 })

    expected = 'h2o,host=aws,region=us level=5i,saturation="99%" 123'
    assert_requested(:post, 'http://localhost:9999/api/v2/write?bucket=my-bucket&org=my-org&precision=ns',
                     times: 1, body: expected)
  end

  def test_write_collection
    stub_request(:any, 'http://localhost:9999/api/v2/write?bucket=my-bucket&org=my-org&precision=ns')
      .to_return(status: 204)
    client = InfluxDB2::Client.new('http://localhost:9999', 'my-token',
                                   bucket: 'my-bucket',
                                   org: 'my-org',
                                   precision: InfluxDB2::WritePrecision::NANOSECOND,
                                   use_ssl: false)

    point = InfluxDB2::Point.new(name: 'h2o')
                            .add_tag('location', 'europe')
                            .add_field('level', 2)

    hash = { name: 'h2o',
             tags: { host: 'aws', region: 'us' },
             fields: { level: 5, saturation: '99%' }, time: 123 }

    client.create_write_api.write(data: ['h2o,location=west value=33i 15', nil, '', point, hash])

    expected = 'h2o,location=west value=33i 15\nh2o,location=europe level=2i'\
               '\nh2o,host=aws,region=us level=5i,saturation="99%" 123'
    assert_requested(:post, 'http://localhost:9999/api/v2/write?bucket=my-bucket&org=my-org&precision=ns',
                     times: 1, body: expected)
  end

  def test_authorization_header
    stub_request(:any, 'http://localhost:9999/api/v2/write?bucket=my-bucket&org=my-org&precision=ns')
      .to_return(status: 204)
    client = InfluxDB2::Client.new('http://localhost:9999', 'my-token',
                                   bucket: 'my-bucket',
                                   org: 'my-org',
                                   precision: InfluxDB2::WritePrecision::NANOSECOND,
                                   use_ssl: false)

    client.create_write_api.write(data: 'h2o,location=west value=33i 15')

    assert_requested(:post, 'http://localhost:9999/api/v2/write?bucket=my-bucket&org=my-org&precision=ns',
                     times: 1, headers: { 'Authorization' => 'Token my-token' })
  end

  def test_without_data
    stub_request(:any, 'http://localhost:9999/api/v2/write?bucket=my-bucket&org=my-org&precision=ns')
      .to_return(status: 204)
    client = InfluxDB2::Client.new('http://localhost:9999', 'my-token',
                                   bucket: 'my-bucket',
                                   org: 'my-org',
                                   precision: InfluxDB2::WritePrecision::NANOSECOND)

    client.create_write_api.write(data: '')

    assert_requested(:post, 'http://localhost:9999/api/v2/write?bucket=my-bucket&org=my-org&precision=ns', times: 0)
  end

  def test_influx_exception
    error_body = '{"code":"invalid","message":"unable to parse '\
                 '\'h2o_feet, location=coyote_creek water_level=1.0 1\': missing tag key"}'

    stub_request(:any, 'http://localhost:9999/api/v2/write?bucket=my-bucket&org=my-org&precision=ns')
      .to_return(status: 400, headers: { 'X-Platform-Error-Code' => 'invalid' }, body: error_body)

    client = InfluxDB2::Client.new('http://localhost:9999', 'my-token',
                                   bucket: 'my-bucket',
                                   org: 'my-org',
                                   precision: InfluxDB2::WritePrecision::NANOSECOND,
                                   use_ssl: false)

    error = assert_raises InfluxDB2::InfluxError do
      client.create_write_api.write(data: 'h2o,location=west value=33i 15')
    end

    assert_equal '400', error.code
    assert_equal 'invalid', error.reference
    assert_equal "unable to parse 'h2o_feet, location=coyote_creek water_level=1.0 1': missing tag key", error.message
  end

  def test_follow_redirect
    stub_request(:any, 'http://localhost:9999/api/v2/write?bucket=my-bucket&org=my-org&precision=ns')
      .to_return(status: 307, headers:
          { 'location' => 'http://localhost:9090/api/v2/write?bucket=my-bucket&org=my-org&precision=ns' })
      .then.to_return(status: 204)
    stub_request(:any, 'http://localhost:9090/api/v2/write?bucket=my-bucket&org=my-org&precision=ns')
      .to_return(status: 204)

    client = InfluxDB2::Client.new('http://localhost:9999', 'my-token',
                                   bucket: 'my-bucket',
                                   org: 'my-org',
                                   precision: InfluxDB2::WritePrecision::NANOSECOND,
                                   use_ssl: false)

    client.create_write_api.write(data: 'h2o,location=west value=33i 15')

    assert_requested(:post, 'http://localhost:9999/api/v2/write?bucket=my-bucket&org=my-org&precision=ns',
                     times: 1, body: 'h2o,location=west value=33i 15')
    assert_requested(:post, 'http://localhost:9090/api/v2/write?bucket=my-bucket&org=my-org&precision=ns',
                     times: 1, body: 'h2o,location=west value=33i 15')
  end

  def test_follow_redirect_max
    stub_request(:any, 'http://localhost:9999/api/v2/write?bucket=my-bucket&org=my-org&precision=ns')
      .to_return(status: 307, headers:
          { 'location' => 'http://localhost:9999/api/v2/write?bucket=my-bucket&org=my-org&precision=ns' })

    client = InfluxDB2::Client.new('http://localhost:9999', 'my-token',
                                   bucket: 'my-bucket',
                                   org: 'my-org',
                                   precision: InfluxDB2::WritePrecision::NANOSECOND,
                                   max_redirect_count: 5,
                                   use_ssl: false)

    error = assert_raises InfluxDB2::InfluxError do
      client.create_write_api.write(data: 'h2o,location=west value=33i 15')
    end

    assert_equal 'Too many HTTP redirects. Exceeded limit: 5', error.message
  end

  def test_write_precision_constant
    assert_equal InfluxDB2::WritePrecision::SECOND, InfluxDB2::WritePrecision.new.get_from_value('s')
    assert_equal InfluxDB2::WritePrecision::MILLISECOND, InfluxDB2::WritePrecision.new.get_from_value('ms')
    assert_equal InfluxDB2::WritePrecision::MICROSECOND, InfluxDB2::WritePrecision.new.get_from_value('us')
    assert_equal InfluxDB2::WritePrecision::NANOSECOND, InfluxDB2::WritePrecision.new.get_from_value('ns')

    error = assert_raises RuntimeError do
      InfluxDB2::WritePrecision.new.get_from_value('not_supported')
    end

    assert_equal 'The time precision not_supported is not supported.', error.message
  end
end
