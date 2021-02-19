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

module InfluxDB2
  class Environment
    def self.current
      @current ||= InfluxDB2::Environment.new(ENV)
    end

    def self.current=(env)
      @current = env
    end

    def initialize(data)
      @data = data
    end

    def name
      if data['INFLUXDB_ENV']
        data['INFLUXDB_ENV']
      elsif defined?(Rails) && Rails.respond_to?(:env)
        Rails.env.to_s
      else
        data['RAILS_ENV'] || data['RACK_ENV'] || data['ENV'] || 'development'
      end
    end

    def default_write_api
      if test?
        TestWriteApi
      else
        WriteApi
      end
    end

    def production?
      name == 'production'
    end

    def test?
      name == 'test'
    end

    private

    attr_reader :data
  end
end
