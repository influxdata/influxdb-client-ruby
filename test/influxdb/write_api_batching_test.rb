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

class WriteApiBatchingTest < MiniTest::Test
  def setup
    WebMock.disable_net_connect!

    @write_options = InfluxDB2::WriteOptions.new(write_type: InfluxDB2::WriteType::BATCHING,
                                                 batch_size: 2, flush_interval: 5_000, retry_interval: 2_000)
    @client = InfluxDB2::Client.new('http://localhost:8086',
                                    'my-token',
                                    bucket: 'my-bucket',
                                    org: 'my-org',
                                    precision: InfluxDB2::WritePrecision::NANOSECOND,
                                    use_ssl: false)

    @write_client = @client.create_write_api(write_options: @write_options)
  end

  def teardown
    @client.close!

    assert_equal true, @write_client.closed

    WebMock.reset!
  end

  def test_batch_configuration
    error = assert_raises ArgumentError do
      InfluxDB2::WriteOptions.new(write_type: InfluxDB2::WriteType::BATCHING, batch_size: 0)
    end
    assert_equal "The 'batch_size' should be positive or zero, but is: 0", error.message

    error = assert_raises ArgumentError do
      InfluxDB2::WriteOptions.new(write_type: InfluxDB2::WriteType::BATCHING, flush_interval: -10)
    end
    assert_equal "The 'flush_interval' should be positive or zero, but is: -10", error.message

    error = assert_raises ArgumentError do
      InfluxDB2::WriteOptions.new(write_type: InfluxDB2::WriteType::BATCHING, retry_interval: 0)
    end
    assert_equal "The 'retry_interval' should be positive or zero, but is: 0", error.message

    InfluxDB2::WriteOptions.new(write_type: InfluxDB2::WriteType::BATCHING, jitter_interval: 0)
    error = assert_raises ArgumentError do
      InfluxDB2::WriteOptions.new(write_type: InfluxDB2::WriteType::BATCHING, jitter_interval: -10)
    end
    assert_equal "The 'jitter_interval' should be positive number, but is: -10", error.message
  end

  def test_batch_size
    stub_request(:post, 'http://localhost:8086/api/v2/write?bucket=my-bucket&org=my-org&precision=ns')
      .to_return(status: 204)

    @write_client.write(data: 'h2o_feet,location=coyote_creek level\\ water_level=1.0 1')
    @write_client.write(data: 'h2o_feet,location=coyote_creek level\\ water_level=2.0 2')
    @write_client.write(data: 'h2o_feet,location=coyote_creek level\\ water_level=3.0 3')
    @write_client.write(data: 'h2o_feet,location=coyote_creek level\\ water_level=4.0 4')

    sleep(1)

    request1 = "h2o_feet,location=coyote_creek level\\ water_level=1.0 1\n" \
               'h2o_feet,location=coyote_creek level\\ water_level=2.0 2'
    request2 = "h2o_feet,location=coyote_creek level\\ water_level=3.0 3\n" \
               'h2o_feet,location=coyote_creek level\\ water_level=4.0 4'

    assert_requested(:post, 'http://localhost:8086/api/v2/write?bucket=my-bucket&org=my-org&precision=ns',
                     times: 1, body: request1)
    assert_requested(:post, 'http://localhost:8086/api/v2/write?bucket=my-bucket&org=my-org&precision=ns',
                     times: 1, body: request2)
  end

  def test_batch_size_group_by
    stub_request(:post, 'http://localhost:8086/api/v2/write?bucket=my-bucket&org=my-org&precision=ns')
      .to_return(status: 204)
    stub_request(:post, 'http://localhost:8086/api/v2/write?bucket=my-bucket&org=my-org&precision=s')
      .to_return(status: 204)
    stub_request(:post, 'http://localhost:8086/api/v2/write?bucket=my-bucket&org=my-org-a&precision=ns')
      .to_return(status: 204)
    stub_request(:post, 'http://localhost:8086/api/v2/write?bucket=my-bucket2&org=my-org-a&precision=ns')
      .to_return(status: 204)

    bucket = 'my-bucket'
    bucket2 = 'my-bucket2'
    org_a = 'my-org-a'

    @write_client.write(data: 'h2o_feet,location=coyote_creek level\\ water_level=1.0 1', bucket: bucket, org: 'my-org')
    @write_client.write(data: 'h2o_feet,location=coyote_creek level\\ water_level=2.0 2', bucket: bucket, org: 'my-org',
                        precision: InfluxDB2::WritePrecision::SECOND)
    @write_client.write(data: 'h2o_feet,location=coyote_creek level\\ water_level=3.0 3', bucket: bucket, org: org_a)
    @write_client.write(data: 'h2o_feet,location=coyote_creek level\\ water_level=4.0 4', bucket: bucket, org: org_a)
    @write_client.write(data: 'h2o_feet,location=coyote_creek level\\ water_level=5.0 5', bucket: bucket2, org: org_a)
    @write_client.write(data: 'h2o_feet,location=coyote_creek level\\ water_level=6.0 6', bucket: bucket, org: org_a)

    sleep(1)

    assert_requested(:post, 'http://localhost:8086/api/v2/write?bucket=my-bucket&org=my-org&precision=ns',
                     times: 1, body: 'h2o_feet,location=coyote_creek level\\ water_level=1.0 1')
    assert_requested(:post, 'http://localhost:8086/api/v2/write?bucket=my-bucket&org=my-org&precision=s',
                     times: 1, body: 'h2o_feet,location=coyote_creek level\\ water_level=2.0 2')
    assert_requested(:post, 'http://localhost:8086/api/v2/write?bucket=my-bucket&org=my-org-a&precision=ns',
                     times: 1, body: "h2o_feet,location=coyote_creek level\\ water_level=3.0 3\n" \
                    'h2o_feet,location=coyote_creek level\\ water_level=4.0 4')
    assert_requested(:post, 'http://localhost:8086/api/v2/write?bucket=my-bucket2&org=my-org-a&precision=ns',
                     times: 1, body: 'h2o_feet,location=coyote_creek level\\ water_level=5.0 5')
    assert_requested(:post, 'http://localhost:8086/api/v2/write?bucket=my-bucket&org=my-org-a&precision=ns',
                     times: 1, body: 'h2o_feet,location=coyote_creek level\\ water_level=6.0 6')
  end

  def test_flush_interval
    stub_request(:post, 'http://localhost:8086/api/v2/write?bucket=my-bucket&org=my-org&precision=ns')
      .to_return(status: 204)

    request1 = "h2o_feet,location=coyote_creek level\\ water_level=1.0 1\n" \
               'h2o_feet,location=coyote_creek level\\ water_level=2.0 2'
    request2 = 'h2o_feet,location=coyote_creek level\\ water_level=3.0 3'

    @write_client.write(data: 'h2o_feet,location=coyote_creek level\\ water_level=1.0 1')
    @write_client.write(data: 'h2o_feet,location=coyote_creek level\\ water_level=2.0 2')

    sleep(1)

    assert_requested(:post, 'http://localhost:8086/api/v2/write?bucket=my-bucket&org=my-org&precision=ns',
                     times: 1, body: request1)

    @write_client.write(data: 'h2o_feet,location=coyote_creek level\\ water_level=3.0 3')

    sleep(2)

    assert_requested(:post, 'http://localhost:8086/api/v2/write?bucket=my-bucket&org=my-org&precision=ns',
                     times: 0, body: request2)

    sleep(3)

    assert_requested(:post, 'http://localhost:8086/api/v2/write?bucket=my-bucket&org=my-org&precision=ns',
                     times: 1, body: request2)
  end

  def test_flush_all_by_close_client
    stub_request(:post, 'http://localhost:8086/api/v2/write?bucket=my-bucket&org=my-org&precision=ns')
      .to_return(status: 204)

    @client.close!

    @write_options = InfluxDB2::WriteOptions.new(write_type: InfluxDB2::WriteType::BATCHING,
                                                 batch_size: 10, flush_interval: 5_000)
    @client = InfluxDB2::Client.new('http://localhost:8086',
                                    'my-token',
                                    bucket: 'my-bucket',
                                    org: 'my-org',
                                    precision: InfluxDB2::WritePrecision::NANOSECOND,
                                    use_ssl: false)

    @write_client = @client.create_write_api(write_options: @write_options)

    @write_client.write(data: 'h2o_feet,location=coyote_creek level\\ water_level=1.0 1')
    @write_client.write(data: 'h2o_feet,location=coyote_creek level\\ water_level=2.0 2')
    @write_client.write(data: 'h2o_feet,location=coyote_creek level\\ water_level=3.0 3')

    assert_requested(:post, 'http://localhost:8086/api/v2/write?bucket=my-bucket&org=my-org&precision=ns',
                     times: 0, body: 'h2o_feet,location=coyote_creek level\\ water_level=3.0 3')

    @client.close!

    assert_requested(:post, 'http://localhost:8086/api/v2/write?bucket=my-bucket&org=my-org&precision=ns',
                     times: 1, body: "h2o_feet,location=coyote_creek level\\ water_level=1.0 1\n" \
                     "h2o_feet,location=coyote_creek level\\ water_level=2.0 2\n" \
                     'h2o_feet,location=coyote_creek level\\ water_level=3.0 3')
  end

  def test_jitter_interval
    @client.close!

    @client = InfluxDB2::Client.new('http://localhost:8086',
                                    'my-token',
                                    bucket: 'my-bucket',
                                    org: 'my-org',
                                    precision: InfluxDB2::WritePrecision::NANOSECOND,
                                    use_ssl: false)

    @write_options = InfluxDB2::WriteOptions.new(write_type: InfluxDB2::WriteType::BATCHING,
                                                 batch_size: 2, flush_interval: 5_000, jitter_interval: 2_000)
    @write_client = @client.create_write_api(write_options: @write_options)

    stub_request(:post, 'http://localhost:8086/api/v2/write?bucket=my-bucket&org=my-org&precision=ns')
      .to_return(status: 204)

    request = "h2o_feet,location=coyote_creek water_level=1.0 1\n" \
               'h2o_feet,location=coyote_creek water_level=2.0 2'

    @write_client.write(data: ['h2o_feet,location=coyote_creek water_level=1.0 1',
                               'h2o_feet,location=coyote_creek water_level=2.0 2'])

    sleep(2)

    assert_requested(:post, 'http://localhost:8086/api/v2/write?bucket=my-bucket&org=my-org&precision=ns',
                     times: 1, body: request)
  end
end

class WriteApiRetryStrategyTest < MiniTest::Test
  def setup
    WebMock.disable_net_connect!

    @logger = MockLogger.new
    @write_options = InfluxDB2::WriteOptions.new(write_type: InfluxDB2::WriteType::BATCHING,
                                                 batch_size: 2, flush_interval: 5_000, retry_interval: 2_000)
    @client = InfluxDB2::Client.new('http://localhost:8086',
                                    'my-token',
                                    bucket: 'my-bucket',
                                    org: 'my-org',
                                    precision: InfluxDB2::WritePrecision::NANOSECOND,
                                    use_ssl: false,
                                    logger: @logger)

    @write_client = @client.create_write_api(write_options: @write_options)
  end

  def teardown
    @client.close!

    assert_equal true, @write_client.closed

    WebMock.reset!
  end

  def test_retry_interval_by_config
    error_body = '{"code":"temporarily unavailable","message":"Token is temporarily over quota. '\
                 'The Retry-After header describes when to try the write again."}'

    stub_request(:post, 'http://localhost:8086/api/v2/write?bucket=my-bucket&org=my-org&precision=ns')
      .to_return(status: 429, headers: { 'X-Platform-Error-Code' => 'temporarily unavailable' }, body: error_body).then
      .to_return(status: 204)

    request = "h2o_feet,location=coyote_creek water_level=1.0 1\n" \
               'h2o_feet,location=coyote_creek water_level=2.0 2'

    @write_client.write(data: ['h2o_feet,location=coyote_creek water_level=1.0 1',
                               'h2o_feet,location=coyote_creek water_level=2.0 2'])

    sleep(0.5)

    assert_requested(:post, 'http://localhost:8086/api/v2/write?bucket=my-bucket&org=my-org&precision=ns',
                     times: 1, body: request)

    sleep(1)

    assert_requested(:post, 'http://localhost:8086/api/v2/write?bucket=my-bucket&org=my-org&precision=ns',
                     times: 1, body: request)

    sleep(5)

    assert_requested(:post, 'http://localhost:8086/api/v2/write?bucket=my-bucket&org=my-org&precision=ns',
                     times: 2, body: request)
  end

  def test_retry_interval_by_header
    error_body = '{"code":"temporarily unavailable","message":"Server is temporarily unavailable to accept writes. '\
                 'The Retry-After header describes when to try the write again."}'

    stub_request(:post, 'http://localhost:8086/api/v2/write?bucket=my-bucket&org=my-org&precision=ns')
      .to_return(status: 503, headers: { 'X-Platform-Error-Code' => 'temporarily unavailable', 'Retry-After' => '3' },
                 body: error_body).then
      .to_return(status: 204)

    request = "h2o_feet,location=coyote_creek water_level=1.0 1\n" \
               'h2o_feet,location=coyote_creek water_level=2.0 2'

    @write_client.write(data: ['h2o_feet,location=coyote_creek water_level=1.0 1',
                               InfluxDB2::Point.new(name: 'h2o_feet')
                                               .add_tag('location', 'coyote_creek')
                                               .add_field('water_level', 2.0)
                                               .time(2, InfluxDB2::WritePrecision::NANOSECOND)])

    sleep(0.5)

    assert_requested(:post, 'http://localhost:8086/api/v2/write?bucket=my-bucket&org=my-org&precision=ns',
                     times: 1, body: request)

    sleep(1)

    assert_requested(:post, 'http://localhost:8086/api/v2/write?bucket=my-bucket&org=my-org&precision=ns',
                     times: 1, body: request)

    sleep(1)

    assert_requested(:post, 'http://localhost:8086/api/v2/write?bucket=my-bucket&org=my-org&precision=ns',
                     times: 1, body: request)

    sleep(1)

    assert_requested(:post, 'http://localhost:8086/api/v2/write?bucket=my-bucket&org=my-org&precision=ns',
                     times: 2, body: request)
  end

  def test_max_retries
    error_body = '{"code":"temporarily unavailable","message":"Server is temporarily unavailable to accept writes. '\
                 'The Retry-After header describes when to try the write again."}'

    headers = { 'X-Platform-Error-Code' => 'temporarily unavailable' }

    stub_request(:post, 'http://localhost:8086/api/v2/write?bucket=my-bucket&org=my-org&precision=ns')
      .to_return(status: 429, headers: headers, body: error_body).then # retry
      .to_return(status: 429, headers: headers, body: error_body).then # retry
      .to_return(status: 429, headers: headers, body: error_body).then # retry
      .to_return(status: 429, headers: headers, body: error_body).then # retry
      .to_return(status: 429, headers: headers, body: error_body) # not called

    point = InfluxDB2::Point.new(name: 'h2o')
                            .add_tag('location', 'europe')
                            .add_field('level', 2.0)

    request = 'h2o,location=europe level=2.0'

    write_options = InfluxDB2::WriteOptions.new(write_type: InfluxDB2::WriteType::BATCHING,
                                                batch_size: 1, retry_interval: 2_000, max_retries: 3,
                                                max_retry_delay: 5_000, exponential_base: 2)

    @client.create_write_api(write_options: write_options).write(data: point)

    sleep(15)

    assert_requested(:post, 'http://localhost:8086/api/v2/write?bucket=my-bucket&org=my-org&precision=ns',
                     times: 4, body: request)
  end

  def test_influx_exception
    error_body = '{"code":"invalid","message":"unable to parse '\
                 '\'h2o_feet, location=coyote_creek water_level=1.0 1\': missing tag key"}'

    stub_request(:any, 'http://localhost:8086/api/v2/write?bucket=my-bucket&org=my-org&precision=ns')
      .to_return(status: 400, headers: { 'X-Platform-Error-Code' => 'invalid' }, body: error_body)

    write_options = InfluxDB2::WriteOptions.new(write_type: InfluxDB2::WriteType::BATCHING,
                                                batch_size: 1, retry_interval: 2_000, max_retries: 3,
                                                max_retry_delay: 5_000, exponential_base: 2,
                                                batch_abort_on_exception: true)

    error = assert_raises InfluxDB2::InfluxError do
      @client.create_write_api(write_options: write_options).write(data: 'h2o,location=west value=33i 15')

      sleep(1)
    end

    assert_equal '400', error.code
    assert_equal 'invalid', error.reference
    assert_equal "unable to parse 'h2o_feet, location=coyote_creek water_level=1.0 1': missing tag key", error.message
  end

  def test_max_retries_by_header
    error_body = '{"code":"temporarily unavailable","message":"Server is temporarily unavailable to accept writes. '\
                 'The Retry-After header describes when to try the write again."}'

    headers = { 'X-Platform-Error-Code' => 'temporarily unavailable', 'Retry-After' => '3' }

    stub_request(:post, 'http://localhost:8086/api/v2/write?bucket=my-bucket&org=my-org&precision=ns')
      .to_return(status: 429, headers: headers, body: error_body).then # retry
      .to_return(status: 429, headers: headers, body: error_body).then # retry
      .to_return(status: 429, headers: headers, body: error_body).then # retry
      .to_return(status: 429, headers: headers, body: error_body).then # retry
      .to_return(status: 429, headers: headers, body: error_body) # not called

    point = InfluxDB2::Point.new(name: 'h2o')
                            .add_tag('location', 'europe')
                            .add_field('level', 2.0)

    request = 'h2o,location=europe level=2.0'

    write_options = InfluxDB2::WriteOptions.new(write_type: InfluxDB2::WriteType::BATCHING,
                                                batch_size: 1, retry_interval: 2_000, max_retries: 3,
                                                max_retry_delay: 5_000, exponential_base: 2)

    @client.create_write_api(write_options: write_options).write(data: point)

    sleep(0.5)

    assert_requested(:post, 'http://localhost:8086/api/v2/write?bucket=my-bucket&org=my-org&precision=ns',
                     times: 1, body: request)

    sleep(3)

    assert_requested(:post, 'http://localhost:8086/api/v2/write?bucket=my-bucket&org=my-org&precision=ns',
                     times: 2, body: request)

    sleep(3)

    assert_requested(:post, 'http://localhost:8086/api/v2/write?bucket=my-bucket&org=my-org&precision=ns',
                     times: 3, body: request)

    sleep(3)

    assert_requested(:post, 'http://localhost:8086/api/v2/write?bucket=my-bucket&org=my-org&precision=ns',
                     times: 4, body: request)

    sleep(3)

    assert_requested(:post, 'http://localhost:8086/api/v2/write?bucket=my-bucket&org=my-org&precision=ns',
                     times: 4, body: request)
  end

  def test_connection_error
    error_message = 'Failed to open TCP connection to localhost:8086' \
        '(Connection refused - connect(2) for "localhost" port 8086)'

    stub_request(:post, 'http://localhost:8086/api/v2/write?bucket=my-bucket&org=my-org&precision=ns')
      .to_raise(Errno::ECONNREFUSED.new(error_message))
      .to_raise(Errno::ECONNREFUSED.new(error_message))
      .to_raise(Errno::ECONNREFUSED.new(error_message))
      .to_raise(Errno::ECONNREFUSED.new(error_message))
      .to_raise(Errno::ECONNREFUSED.new(error_message))

    point = InfluxDB2::Point.new(name: 'h2o')
                            .add_tag('location', 'europe')
                            .add_field('level', 2.0)

    request = 'h2o,location=europe level=2.0'

    write_options = InfluxDB2::WriteOptions.new(write_type: InfluxDB2::WriteType::BATCHING,
                                                batch_size: 1, retry_interval: 1000, max_retries: 3,
                                                max_retry_delay: 5_000, exponential_base: 2)

    @client.create_write_api(write_options: write_options).write(data: point)

    # random sleep intervals
    # [1000, 2000], [2000, 4000], [4000, 5000]
    sleep(11)
    assert_requested(:post, 'http://localhost:8086/api/v2/write?bucket=my-bucket&org=my-org&precision=ns',
                     times: 4, body: request)
  end

  def test_write_connection_error
    stub_request(:post, 'http://localhost:8086/api/v2/write?bucket=my-bucket&org=my-org&precision=ns')
      .to_raise(Errno::ECONNREFUSED.new(''))
      .to_raise(Errno::ECONNREFUSED.new(''))
      .to_return(status: 204)

    point = InfluxDB2::Point.new(name: 'h2o')
                            .add_tag('location', 'europe')
                            .add_field('level', 2.0)

    request = 'h2o,location=europe level=2.0'

    write_options = InfluxDB2::WriteOptions.new(write_type: InfluxDB2::WriteType::BATCHING,
                                                batch_size: 1, retry_interval: 2_000, max_retries: 3,
                                                max_retry_delay: 5_000, exponential_base: 2)

    @client.create_write_api(write_options: write_options).write(data: point)

    sleep(10)

    assert_requested(:post, 'http://localhost:8086/api/v2/write?bucket=my-bucket&org=my-org&precision=ns',
                     times: 3, body: request)
  end

  def test_abort_on_exception
    error_body = '{"code":"invalid","message":"unable to parse '\
                 '\'h2o,location=europe 1\'"}'

    stub_request(:any, 'http://localhost:8086/api/v2/write?bucket=my-bucket&org=my-org&precision=ns')
      .to_return(status: 400, headers: { 'X-Platform-Error-Code' => 'invalid' }, body: error_body)
      .to_return(status: 204)

    write_options = InfluxDB2::WriteOptions.new(write_type: InfluxDB2::WriteType::BATCHING,
                                                batch_size: 1, retry_interval: 500, max_retries: 1,
                                                max_retry_delay: 5_000, exponential_base: 1,
                                                batch_abort_on_exception: true)

    write_api = @client.create_write_api(write_options: write_options)

    error = assert_raises InfluxDB2::InfluxError do
      write_api.write(data: 'h2o,location=europe 1')
      write_api.write(data: 'h2o,location=europe level=2.0 1')

      sleep(2)
    end

    assert_equal("unable to parse 'h2o,location=europe 1'", error.message)

    assert_requested(:post, 'http://localhost:8086/api/v2/write?bucket=my-bucket&org=my-org&precision=ns',
                     times: 1, body: 'h2o,location=europe 1')

    assert_requested(:post, 'http://localhost:8086/api/v2/write?bucket=my-bucket&org=my-org&precision=ns',
                     times: 0, body: 'h2o,location=europe level=2.0 1')
  end

  def test_abort_on_exception_next_batch
    error_body = '{"code":"invalid","message":"unable to parse '\
                 '\'h2o,location=europe 1\'"}'

    stub_request(:any, 'http://localhost:8086/api/v2/write?bucket=my-bucket&org=my-org&precision=ns')
      .to_return(status: 400, headers: { 'X-Platform-Error-Code' => 'invalid' }, body: error_body)
      .to_return(status: 204)

    write_options = InfluxDB2::WriteOptions.new(write_type: InfluxDB2::WriteType::BATCHING,
                                                batch_size: 1, retry_interval: 500, max_retries: 1,
                                                max_retry_delay: 5_000, exponential_base: 1)

    write_api = @client.create_write_api(write_options: write_options)

    write_api.write(data: 'h2o,location=europe 1')
    write_api.write(data: 'h2o,location=europe level=2.0 1')

    sleep(2)

    assert_requested(:post, 'http://localhost:8086/api/v2/write?bucket=my-bucket&org=my-org&precision=ns',
                     times: 1, body: 'h2o,location=europe 1')

    assert_requested(:post, 'http://localhost:8086/api/v2/write?bucket=my-bucket&org=my-org&precision=ns',
                     times: 1, body: 'h2o,location=europe level=2.0 1')
  end

  def test_retry_contains_message
    error_body = '{"code":"temporarily unavailable","message":"Server is temporarily unavailable to accept writes."}'

    stub_request(:post, 'http://localhost:8086/api/v2/write?bucket=my-bucket&org=my-org&precision=ns')
      .to_return(status: 429, headers: { 'X-Platform-Error-Code' => 'temporarily unavailable', 'Retry-After' => '3' },
                 body: error_body).then
      .to_return(status: 204)

    request = "h2o_feet,location=coyote_creek water_level=1.0 1\n" \
               'h2o_feet,location=coyote_creek water_level=2.0 2'

    @write_client.write(data: ['h2o_feet,location=coyote_creek water_level=1.0 1',
                               InfluxDB2::Point.new(name: 'h2o_feet')
                                   .add_tag('location', 'coyote_creek')
                                   .add_field('water_level', 2.0)
                                   .time(2, InfluxDB2::WritePrecision::NANOSECOND)])

    sleep(5)

    assert_requested(:post, 'http://localhost:8086/api/v2/write?bucket=my-bucket&org=my-org&precision=ns',
                     times: 2, body: request)

    message = 'The retriable error occurred during writing of data. '\
"Reason: 'Server is temporarily unavailable to accept writes.'. Retry in: 3.0s."

    assert_equal(message, @logger.messages[0][1])
  end

  def test_backoff_time_default
    retries = InfluxDB2::WriteRetry.new

    backoff = retries.get_backoff_time(1)
    assert_gte backoff, 5_000
    assert_lte backoff, 10_000

    backoff = retries.get_backoff_time(2)
    assert_gte backoff, 10_000
    assert_lte backoff, 20_000

    backoff = retries.get_backoff_time(3)
    assert_gte backoff, 20_000
    assert_lte backoff, 40_000

    backoff = retries.get_backoff_time(4)
    assert_gte backoff, 40_000
    assert_lte backoff, 80_000

    backoff = retries.get_backoff_time(5)
    assert_gte backoff, 80_000
    assert_lte backoff, 125_000

    backoff = retries.get_backoff_time(6)
    assert_gte backoff, 80_000
    assert_lte backoff, 125_000
  end

  def test_backoff_time_custom
    retries = InfluxDB2::WriteRetry.new(
      max_retry_delay: 2_000,
      retry_interval: 100,
      exponential_base: 2,
      max_retries: 5
    )

    backoff = retries.get_backoff_time(1)
    assert_gte backoff, 100
    assert_lte backoff, 200

    backoff = retries.get_backoff_time(2)
    assert_gte backoff, 200
    assert_lte backoff, 400

    backoff = retries.get_backoff_time(3)
    assert_gte backoff, 400
    assert_lte backoff, 800

    backoff = retries.get_backoff_time(4)
    assert_gte backoff, 800
    assert_lte backoff, 1_600

    backoff = retries.get_backoff_time(5)
    assert_gte backoff, 1_600
    assert_lte backoff, 2_000
  end

  def test_write_error_plain_retry
    error_body = 'Service Unavailable'
    stub_request(:any, 'http://localhost:8086/api/v2/write?bucket=my-bucket&org=my-org&precision=ns')
      .to_return(status: 503, headers: { 'content-type' => 'text/plain', 'Retry-After' => '2' }, body: error_body)
      .to_return(status: 503, headers: { 'content-type' => 'text/plain' }, body: error_body).to_return(status: 204)

    client = InfluxDB2::Client.new('http://localhost:8086', 'my-token',
                                   bucket: 'my-bucket',
                                   org: 'my-org',
                                   precision: InfluxDB2::WritePrecision::NANOSECOND,
                                   use_ssl: false)

    @write_options = InfluxDB2::WriteOptions.new(write_type: InfluxDB2::WriteType::BATCHING,
                                                 batch_size: 1, flush_interval: 1_000, retry_interval: 1_000)

    write_api = client.create_write_api(write_options: @write_options)
    request = 'h2o,location=west value=33i 15'
    write_api.write(data: request)

    sleep(10)
    assert_requested(:post, 'http://localhost:8086/api/v2/write?bucket=my-bucket&org=my-org&precision=ns',
                     times: 3, body: request)
  end
end
