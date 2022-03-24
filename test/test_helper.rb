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

require 'simplecov'
SimpleCov.start do
  add_filter 'lib/influxdb2/client/models/'
  add_filter 'test/influxdb'
end

if ENV['CI'] == 'true'
  require 'simplecov-cobertura'
  SimpleCov.formatter = SimpleCov::Formatter::CoberturaFormatter
end

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'influxdb-client'

require 'minitest/autorun'
require 'minitest/reporters'
Minitest::Reporters.use! unless ENV['RM_INFO']

require 'webmock/minitest'

class MockLogger
  attr_accessor :messages

  def initialize
    @messages = []
  end

  def add(level, &block)
    line = yield(block)
    print("#{line}\n")
    @messages << [level, line]
  end
end

def assert_gt(val1, val2)
  assert_operator val1, :>, val2
end

def assert_gte(val1, val2)
  assert_operator val1, :>=, val2
end

def assert_lt(val1, val2)
  assert_operator val1, :<, val2
end

def assert_lte(val1, val2)
  assert_operator val1, :<=, val2
end
