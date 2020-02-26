module InfluxDB2
  # InfluxError that is raised during HTTP communication.
  class InfluxError < StandardError
    # HTTP status code
    attr_reader :code
    # Reference code unique to the error type
    attr_reader :reference
    # The Retry-After header describes when to try the request again.
    attr_reader :retry_after

    def initialize(message:, code:, reference:, retry_after:)
      super(message)

      @code = code
      @reference = reference
      @retry_after = retry_after
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
  end
end
