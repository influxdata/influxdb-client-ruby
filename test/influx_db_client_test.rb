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

class InfluxDBClientTest < Minitest::Test
  def test_defined_version_number
    refute_nil ::InfluxDBClient::VERSION
  end

  def test_client_new
    refute_nil InfluxDBClient::Client.new(url: 'http://localhost:9999', token: 'my-token')
  end

  def test_client_hash
    client1 = InfluxDBClient::Client.new(url: 'http://localhost:9999', token: 'my-token')
    client2 = InfluxDBClient::Client.new(url: 'http://localhost:9999', token: 'my-token-diff')

    refute_equal client1.hash, client2.hash
    assert_equal client1.hash, client1.hash
  end

  def test_client_eq
    client1 = InfluxDBClient::Client.new(url: 'http://localhost:9999', token: 'my-token')
    client2 = InfluxDBClient::Client.new(url: 'http://localhost:9999', token: 'my-token-diff')

    refute_equal client1, client2
    assert_equal client1, client1
  end

  def test_client_options
    client = InfluxDBClient::Client.new(url: 'http://localhost:9999', token: 'my-token')

    assert_equal 'http://localhost:9999', client.options[:url]
    assert_equal 'my-token', client.options[:token]
  end

  def test_close
    client = InfluxDBClient::Client.new(url: 'http://localhost:9999', token: 'my-token')

    assert_equal true, client.close
    assert_equal true, client.close
  end

  def test_get_write_api
    client = InfluxDBClient::Client.new(url: 'http://localhost:9999', token: 'my-token')

    write_api = client.create_write_api

    refute_nil write_api
    assert_instance_of InfluxDBClient::WriteApi, write_api
  end
end
