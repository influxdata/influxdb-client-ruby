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
  def test_defined_version_number
    refute_nil ::InfluxDB::VERSION
  end

  def test_client_new
    refute_nil InfluxDB::Client.new('http://localhost:9999', 'my-token')
  end

  def test_client_hash
    client1 = InfluxDB::Client.new('http://localhost:9999', 'my-token')
    client2 = InfluxDB::Client.new('http://localhost:9999', 'my-token-diff')

    refute_equal client1.hash, client2.hash
    assert_equal client1.hash, client1.hash
  end

  def test_client_eq
    client1 = InfluxDB::Client.new('http://localhost:9999', 'my-token')
    client2 = InfluxDB::Client.new('http://localhost:9999', 'my-token-diff')

    refute_equal client1, client2
    assert_equal client1, client1
  end

  def test_client_options
    client = InfluxDB::Client.new('http://localhost:9999', 'my-token')

    assert_equal 'http://localhost:9999', client.options[:url]
    assert_equal 'my-token', client.options[:token]
  end

  def test_close
    client = InfluxDB::Client.new('http://localhost:9999', 'my-token')

    assert_equal true, client.close!
    assert_equal true, client.close!
  end

  def test_get_write_api
    client = InfluxDB::Client.new('http://localhost:9999', 'my-token')

    write_api = client.create_write_api

    refute_nil write_api
    assert_instance_of InfluxDB::WriteApi, write_api
  end
end
