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

class ApisTest < Minitest::Test
  attr_reader :main_client

  def setup
    WebMock.disable_net_connect!
    @main_client = InfluxDB2::Client.new('http://localhost:9086', 'my-token')
  end

  def teardown
    @main_client.close!
  end

  def test_defined_version_number
    refute_nil InfluxDB2::API::VERSION
  end

  def test_initialize_api_client
    refute_nil InfluxDB2::API::Client.new(@main_client)
  end

  def test_create_apis
    client = InfluxDB2::API::Client.new(@main_client)
    refute_nil client.create_authorizations_api
    refute_nil client.create_buckets_api
    refute_nil client.create_organizations_api
    refute_nil client.create_users_api
    refute_nil client.create_labels_api
  end

  def test_headers
    stub_request(:get, 'http://localhost:9086/api/v2/buckets')
      .to_return(body: '{}', headers: { 'Content-Type' => 'application/json' })

    client = InfluxDB2::API::Client.new(@main_client)
    bucket_api = client.create_buckets_api
    bucket_api.get_buckets

    headers = {
      'Accept' => 'application/json',
      'Authorization' => 'Token my-token',
      'Content-Type' => 'application/json',
      'Expect' => '',
      'User-Agent' => "influxdb-client-ruby/#{InfluxDB2::VERSION}"
    }
    assert_requested(:get, 'http://localhost:9086/api/v2/buckets', times: 1, headers: headers)
  end
end
