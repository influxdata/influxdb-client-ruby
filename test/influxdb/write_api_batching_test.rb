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
                                                 batch_size: 2, flush_interval: 5_000)
    @client = InfluxDB2::Client.new('http://localhost:9999',
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

  def test_batch_size
    stub_request(:post, 'http://localhost:9999/api/v2/write?bucket=my-bucket&org=my-org&precision=ns')
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

    assert_requested(:post, 'http://localhost:9999/api/v2/write?bucket=my-bucket&org=my-org&precision=ns',
                     times: 1, body: request1)
    assert_requested(:post, 'http://localhost:9999/api/v2/write?bucket=my-bucket&org=my-org&precision=ns',
                     times: 1, body: request2)
  end

  def test_batch_size_group_by
    stub_request(:post, 'http://localhost:9999/api/v2/write?bucket=my-bucket&org=my-org&precision=ns')
      .to_return(status: 204)
    stub_request(:post, 'http://localhost:9999/api/v2/write?bucket=my-bucket&org=my-org&precision=s')
      .to_return(status: 204)
    stub_request(:post, 'http://localhost:9999/api/v2/write?bucket=my-bucket&org=my-org-a&precision=ns')
      .to_return(status: 204)
    stub_request(:post, 'http://localhost:9999/api/v2/write?bucket=my-bucket2&org=my-org-a&precision=ns')
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

    assert_requested(:post, 'http://localhost:9999/api/v2/write?bucket=my-bucket&org=my-org&precision=ns',
                     times: 1, body: 'h2o_feet,location=coyote_creek level\\ water_level=1.0 1')
    assert_requested(:post, 'http://localhost:9999/api/v2/write?bucket=my-bucket&org=my-org&precision=s',
                     times: 1, body: 'h2o_feet,location=coyote_creek level\\ water_level=2.0 2')
    assert_requested(:post, 'http://localhost:9999/api/v2/write?bucket=my-bucket&org=my-org-a&precision=ns',
                     times: 1, body: "h2o_feet,location=coyote_creek level\\ water_level=3.0 3\n" \
                    'h2o_feet,location=coyote_creek level\\ water_level=4.0 4')
    assert_requested(:post, 'http://localhost:9999/api/v2/write?bucket=my-bucket2&org=my-org-a&precision=ns',
                     times: 1, body: 'h2o_feet,location=coyote_creek level\\ water_level=5.0 5')
    assert_requested(:post, 'http://localhost:9999/api/v2/write?bucket=my-bucket&org=my-org-a&precision=ns',
                     times: 1, body: 'h2o_feet,location=coyote_creek level\\ water_level=6.0 6')
  end

  def test_flush_interval
    stub_request(:post, 'http://localhost:9999/api/v2/write?bucket=my-bucket&org=my-org&precision=ns')
      .to_return(status: 204)

    request1 = "h2o_feet,location=coyote_creek level\\ water_level=1.0 1\n" \
               'h2o_feet,location=coyote_creek level\\ water_level=2.0 2'
    request2 = 'h2o_feet,location=coyote_creek level\\ water_level=3.0 3'

    @write_client.write(data: 'h2o_feet,location=coyote_creek level\\ water_level=1.0 1')
    @write_client.write(data: 'h2o_feet,location=coyote_creek level\\ water_level=2.0 2')

    sleep(1)

    assert_requested(:post, 'http://localhost:9999/api/v2/write?bucket=my-bucket&org=my-org&precision=ns',
                     times: 1, body: request1)

    @write_client.write(data: 'h2o_feet,location=coyote_creek level\\ water_level=3.0 3')

    sleep(2)

    assert_requested(:post, 'http://localhost:9999/api/v2/write?bucket=my-bucket&org=my-org&precision=ns',
                     times: 0, body: request2)

    sleep(3)

    assert_requested(:post, 'http://localhost:9999/api/v2/write?bucket=my-bucket&org=my-org&precision=ns',
                     times: 1, body: request2)
  end

  def test_flush_all_by_close_client
    stub_request(:post, 'http://localhost:9999/api/v2/write?bucket=my-bucket&org=my-org&precision=ns')
      .to_return(status: 204)

    @write_client.write(data: 'h2o_feet,location=coyote_creek level\\ water_level=1.0 1')
    @write_client.write(data: 'h2o_feet,location=coyote_creek level\\ water_level=2.0 2')
    @write_client.write(data: 'h2o_feet,location=coyote_creek level\\ water_level=3.0 3')

    assert_requested(:post, 'http://localhost:9999/api/v2/write?bucket=my-bucket&org=my-org&precision=ns',
                     times: 0, body: 'h2o_feet,location=coyote_creek level\\ water_level=3.0 3')

    @client.close!

    assert_requested(:post, 'http://localhost:9999/api/v2/write?bucket=my-bucket&org=my-org&precision=ns',
                     times: 1, body: "h2o_feet,location=coyote_creek level\\ water_level=1.0 1\n" \
                     "h2o_feet,location=coyote_creek level\\ water_level=2.0 2\n" \
                     'h2o_feet,location=coyote_creek level\\ water_level=3.0 3')
  end
end
