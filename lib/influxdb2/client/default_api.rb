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
  # default api
  class DefaultApi
    DEFAULT_TIMEOUT = 10
    DEFAULT_REDIRECT_COUNT = 10

    # @param [Hash] options The options to be used by the client.
    def initialize(options:)
      @options = options
      @max_redirect_count = @options[:max_redirect_count] || DEFAULT_REDIRECT_COUNT
    end

    private

    def _post(payload, uri, limit = @max_redirect_count)
      raise InfluxError.from_message("Too many HTTP redirects. Exceeded limit: #{@max_redirect_count}") if limit.zero?

      http = Net::HTTP.new(uri.host, uri.port)
      http.open_timeout = @options[:open_timeout] || DEFAULT_TIMEOUT
      http.write_timeout = @options[:write_timeout] || DEFAULT_TIMEOUT if Net::HTTP.method_defined? :write_timeout
      http.read_timeout = @options[:read_timeout] || DEFAULT_TIMEOUT
      http.use_ssl = @options[:use_ssl].nil? ? true : @options[:use_ssl]

      request = Net::HTTP::Post.new(uri.request_uri)
      request['Authorization'] = "Token #{@options[:token]}"
      request['User-Agent'] = "influxdb-client-ruby/#{InfluxDB2::VERSION}"
      request.body = payload

      begin
        response = http.request(request)
        case response
        when Net::HTTPSuccess then
          response
        when Net::HTTPRedirection then
          location = response['location']
          _post(payload, URI.parse(location), limit - 1)
        else
          raise InfluxError.from_response(response)
        end
      ensure
        http.finish if http.started?
      end
    end

    def _check(key, value)
      raise ArgumentError, "The '#{key}' should be defined as argument or default option: #{@options}" if value.nil?
    end
  end
end
