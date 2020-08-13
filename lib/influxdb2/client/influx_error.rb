module InfluxDB2
  # InfluxError that is raised during HTTP communication.
  class InfluxError < StandardError
    HTTP_ERRORS = [
      EOFError,
      Errno::ECONNREFUSED,
      Errno::ECONNRESET,
      Errno::EINVAL,
      Net::HTTPBadResponse,
      Net::HTTPHeaderSyntaxError,
      Net::ProtocolError,
      Timeout::Error
    ].freeze

    # HTTP status code
    attr_reader :code
    # Reference code unique to the error type
    attr_reader :reference
    # The Retry-After header describes when to try the request again.
    attr_reader :retry_after
    # original error
    attr_reader :original

    def initialize(original = nil, message:, code:, reference:, retry_after:)
      super(message)

      @code = code
      @reference = reference
      @retry_after = retry_after
      @original = original
    end

    def self.from_response(response)
      json = JSON.parse(response.body)
      obj = new(message: json['message'] || '', code: response.code, reference: json['code'] || '',
                retry_after: response['Retry-After'] || '')
      obj
    end

    def self.from_message(message)
      obj = new(message: message, code: '', reference: '', retry_after: '')
      obj
    end

    def self.from_error(error)
      obj = new(error, message: error.message, code: '', reference: '', retry_after: '')
      obj
    end
  end
end
