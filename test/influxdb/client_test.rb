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

class ClientTest < Minitest::Test
  def setup
    WebMock.allow_net_connect!
  end

  def test_defined_version_number
    refute_nil ::InfluxDB2::VERSION
  end

  def test_client_new
    refute_nil InfluxDB2::Client.new('http://localhost:8086', 'my-token')
  end

  def test_client_hash
    client1 = InfluxDB2::Client.new('http://localhost:8086', 'my-token')
    client2 = InfluxDB2::Client.new('http://localhost:8086', 'my-token-diff')

    refute_equal client1.hash, client2.hash
    assert_equal client1.hash, client1.hash
  end

  def test_client_eq
    client1 = InfluxDB2::Client.new('http://localhost:8086', 'my-token')
    client2 = InfluxDB2::Client.new('http://localhost:8086', 'my-token-diff')

    refute_equal client1, client2
    assert_equal client1, client1
  end

  def test_client_options
    client = InfluxDB2::Client.new('http://localhost:8086', 'my-token')

    assert_equal 'http://localhost:8086', client.options[:url]
    assert_equal 'my-token', client.options[:token]
  end

  def test_close
    client = InfluxDB2::Client.new('http://localhost:8086', 'my-token')

    assert_equal true, client.close!
    assert_equal true, client.close!
  end

  def test_get_write_api
    client = InfluxDB2::Client.new('http://localhost:8086', 'my-token')

    write_api = client.create_write_api

    refute_nil write_api
    assert_instance_of InfluxDB2::WriteApi, write_api
  end

  def test_health
    client = InfluxDB2::Client.new('http://localhost:8086', 'my-token', use_ssl: false)

    health = client.health
    assert_equal 'ready for queries and writes', health.message
    assert_equal 'influxdb', health.name
    assert_equal 'pass', health.status
  end

  def test_health_not_running
    client_not_running = InfluxDB2::Client.new('http://localhost:8099', 'my-token', use_ssl: false)
    health = client_not_running.health

    assert_match 'Failed to open TCP connection to localhost:8099', health.message
    assert_equal 'influxdb', health.name
    assert_equal 'fail', health.status
  end

  def test_trailing_slash_in_url
    uri = URI.parse(File.join('http://localhost:8099', '/api/v2/write'))
    assert_equal 'http://localhost:8099/api/v2/write', uri.to_s
    uri = URI.parse(File.join('http://localhost:8099/', '/api/v2/write'))
    assert_equal 'http://localhost:8099/api/v2/write', uri.to_s
  end
end
