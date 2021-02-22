# The MIT License
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the 'Software'), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require 'test_helper'
require 'influxdb2/client/default_api'

class DefaultApiTest < MiniTest::Test
  def setup
    @logger = MockLogger.new
    @api = InfluxDB2::DefaultApi.new(options: { logger: @logger })
  end

  def test_level
    @api.log(:debug, 'debug message')
    @api.log(:warn, 'warn message')
    @api.log(:error, 'error message')
    @api.log(:info, 'info message')
    @api.log(:others, 'others message')

    assert_equal 5, @logger.messages.count

    assert_equal Logger::DEBUG, @logger.messages[0][0]
    assert_equal 'debug message', @logger.messages[0][1]

    assert_equal Logger::WARN, @logger.messages[1][0]
    assert_equal 'warn message', @logger.messages[1][1]

    assert_equal Logger::ERROR, @logger.messages[2][0]
    assert_equal 'error message', @logger.messages[2][1]

    assert_equal Logger::INFO, @logger.messages[3][0]
    assert_equal 'info message', @logger.messages[3][1]

    assert_equal Logger::INFO, @logger.messages[4][0]
    assert_equal 'others message', @logger.messages[4][1]
  end

  def test_supports_false
    @api = InfluxDB2::DefaultApi.new(options: { logger: false })

    @api.log(:info, 'without error')
  end

  def test_default_verify_mode
    http_client = @api.send(:_prepare_http_client, URI.parse('https://localhost:8086'))

    refute_nil http_client
    assert_nil http_client.verify_mode

    http_client.finish if http_client.started?
  end

  def test_default_verify_mode_none
    @api = InfluxDB2::DefaultApi.new(options: { logger: @logger, verify_mode: OpenSSL::SSL::VERIFY_NONE })
    http_client = @api.send(:_prepare_http_client, URI.parse('https://localhost:8086'))

    refute_nil http_client
    assert_equal OpenSSL::SSL::VERIFY_NONE, http_client.verify_mode

    http_client.finish if http_client.started?
  end

  def test_default_verify_mode_peer
    @api = InfluxDB2::DefaultApi.new(options: { logger: @logger, verify_mode: OpenSSL::SSL::VERIFY_PEER })
    http_client = @api.send(:_prepare_http_client, URI.parse('https://localhost:8086'))

    refute_nil http_client
    assert_equal OpenSSL::SSL::VERIFY_PEER, http_client.verify_mode

    http_client.finish if http_client.started?
  end
end
