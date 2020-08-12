module InfluxDB2
  # InfluxError that is raised during HTTP communication.
  class InfluxError < StandardError
    # HTTP status code
    attr_reader :code
    # Reference code unique to the error type
    attr_reader :reference
    # The Retry-After header describes when to try the request again.
    attr_reader :retry_after
    # Connection error flag
    attr_reader :connection_error

    def initialize(message:, code:, reference:, retry_after:, connection_error:)
      super(message)

      @code = code
      @reference = reference
      @retry_after = retry_after
      @connection_error = connection_error
    end

    def self.from_response(response)
      json = JSON.parse(response.body)
      obj = new(message: json['message'] || '', code: response.code, reference: json['code'] || '',
                retry_after: response['Retry-After'] || '', connection_error: false)
      obj
    end

    def self.from_message(message)
      obj = new(message: message, code: '', reference: '', retry_after: '', connection_error: false)
      obj
    end

    def self.from_error(error)
      obj = new(message: error.message, code: '', reference: '', retry_after: '', connection_error: true)
      obj
    end
  end
end
