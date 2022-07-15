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
  # Helper to easy use a logger across the library.
  class LoggingHelper
    # @param [Logger] logger Logger used for logging. Disable logging by set to false.
    def initialize(logger)
      @logger = logger
    end

    def log(level, message)
      return unless @logger

      log_level = case level
                  when :debug then
                    Logger::DEBUG
                  when :warn then
                    Logger::WARN
                  when :error then
                    Logger::ERROR
                  when :fatal then
                    Logger::FATAL
                  else
                    Logger::INFO
                  end

      @logger.add(log_level) { message }
    end

    def before_request(uri, method, headers, payload)
      log(:debug, "-> #{method} #{uri}")
      _headers(headers, '->')
      log(:debug, "-> #{payload}") if payload
    end

    def after_request(http_version, code, message, headers, payload)
      log(:debug, "<- HTTP/#{http_version} #{code} #{message}")
      _headers(headers, '<-')
      log(:debug, "<- #{payload}") if payload
    end

    def _headers(request, prefix)
      request.each do |k, v|
        log(:debug, "#{prefix} #{k}: #{k.casecmp('authorization').zero? ? '***' : v}")
      end
    end
  end
end
