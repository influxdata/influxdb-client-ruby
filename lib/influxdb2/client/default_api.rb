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

require 'logger'

module InfluxDB2
  # default api
  class DefaultApi
    DEFAULT_TIMEOUT = 10
    DEFAULT_REDIRECT_COUNT = 10

    HEADER_CONTENT_TYPE = 'Content-Type'.freeze

    # @param [Hash] options The options to be used by the client.
    def initialize(options:)
      @options = options
      @max_redirect_count = @options[:max_redirect_count] || DEFAULT_REDIRECT_COUNT
    end

    def log(level, message)
      return unless @options[:logger]

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

      @options[:logger].add(log_level) { message }
    end

    def self.create_logger
      Logger.new(STDOUT)
    end

    private

    def _parse_uri(api_path)
      URI.parse(File.join(@options[:url], api_path))
    end

    def _post_json(payload, uri, headers: {})
      _check_arg_type(:headers, headers, Hash)
      _post(payload, uri, headers: headers.merge(HEADER_CONTENT_TYPE => 'application/json'))
    end

    def _post_text(payload, uri, headers: {})
      _check_arg_type(:headers, headers, Hash)
      _post(payload, uri, headers: headers.merge(HEADER_CONTENT_TYPE => 'text/plain'))
    end

    def _post(payload, uri, limit: @max_redirect_count, headers: {})
      _request(payload, uri, limit: limit, headers: headers, request: Net::HTTP::Post)
    end

    def _get(uri, limit: @max_redirect_count, headers: {})
      _request(nil, uri, limit: limit, headers: headers.merge('Accept' => 'application/json'), request: Net::HTTP::Get)
    end

    def _request(payload, uri, limit: @max_redirect_count, headers: {}, request: Net::HTTP::Post)
      raise InfluxError.from_message("Too many HTTP redirects. Exceeded limit: #{@max_redirect_count}") if limit.zero?

      http = Net::HTTP.new(uri.host, uri.port)
      http.open_timeout = @options[:open_timeout] || DEFAULT_TIMEOUT
      http.write_timeout = @options[:write_timeout] || DEFAULT_TIMEOUT if Net::HTTP.method_defined? :write_timeout
      http.read_timeout = @options[:read_timeout] || DEFAULT_TIMEOUT
      http.use_ssl = @options[:use_ssl].nil? ? true : @options[:use_ssl]

      request = request.new(uri.request_uri)
      request['Authorization'] = "Token #{@options[:token]}"
      request['User-Agent'] = "influxdb-client-ruby/#{InfluxDB2::VERSION}"
      headers.each { |k, v| request[k] = v }

      request.body = payload

      begin
        response = http.request(request)
        case response
        when Net::HTTPSuccess then
          response
        when Net::HTTPRedirection then
          location = response['location']
          _post(payload, URI.parse(location), limit: limit - 1, headers: headers)
        else
          raise InfluxError.from_response(response)
        end
      rescue *InfluxError::HTTP_ERRORS => error
        raise InfluxError.from_error(error)
      ensure
        http.finish if http.started?
      end
    end

    def _check_arg_type(name, value, klass)
      raise TypeError, "expected a #{klass.name} for #{name}; got #{value.class.name}" unless value.is_a?(klass)
    end

    def _check(key, value)
      raise ArgumentError, "The '#{key}' should be defined as argument or default option: #{@options}" if value.nil?
    end
  end
end
