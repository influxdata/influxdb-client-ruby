module InfluxDB
  # InfluxError that is raised during HTTP communication.
  class InfluxError < StandardError
    # HTTP status code
    attr_reader :code
    # Reference code unique to the error type
    attr_reader :reference

    def initialize(message:, code:, reference:)
      super(message)

      @code = code
      @reference = reference
    end

    def self.from_response(response)
      json = JSON.parse(response.body)
      obj = new(message: json['message'] || '', code: response.code, reference: json['code'] || '')
      obj
    end
  end
end
