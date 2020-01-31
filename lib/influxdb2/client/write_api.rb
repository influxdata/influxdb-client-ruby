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
  # Precision constants.
  #
  class WritePrecision
    SECOND = 's'.freeze
    MILLISECOND = 'ms'.freeze
    MICROSECOND = 'us'.freeze
    NANOSECOND = 'ns'.freeze

    def get_from_value(value)
      constants = WritePrecision.constants.select { |c| WritePrecision.const_get(c) == value }
      raise "The time precision #{value} is not supported." if constants.empty?

      value
    end
  end

  # Write time series data into InfluxDB.
  #
  class WriteApi < DefaultApi
    # @param [Hash] options The options to be used by the client.
    def initialize(options:)
      super(options: options)
    end

    # Write data into specified Bucket.
    #
    # @example write(data:
    #   [
    #     {
    #       name: 'cpu',
    #       tags: { host: 'server_nl', region: 'us' },
    #       fields: {internal: 5, external: 6},
    #       time: 1422568543702900257
    #     },
    #     {name: 'gpu', fields: {value: 0.9999}}
    #   ],
    #   precision: InfluxDB::WritePrecision::NANOSECOND,
    #   bucket: 'my-bucket',
    #   org: 'my-org'
    # )
    #
    # @example write(data: 'h2o,location=west value=33i 15')
    #
    # @example point = InfluxDB::Point.new(name: 'h2o')
    #   .add_tag('location', 'europe')
    #   .add_field('level', 2)
    #
    # hash = { name: 'h2o', tags: { host: 'aws', region: 'us' }, fields: { level: 5, saturation: '99%' }, time: 123 }
    #
    # write(data: ['h2o,location=west value=33i 15', point, hash])
    #
    # @param [Object] data DataPoints to write into InfluxDB. The data could be represent by [Hash], [Point], [String]
    #   or by collection of these types
    # @param [WritePrecision] precision The precision for the unix timestamps within the body line-protocol
    # @param [String] bucket specifies the destination bucket for writes
    # @param [String] org specifies the destination organization for writes
    def write(data:, precision: nil, bucket: nil, org: nil)
      precision_param = precision || @options[:precision]
      bucket_param = bucket || @options[:bucket]
      org_param = org || @options[:org]
      _check('precision', precision_param)
      _check('bucket', bucket_param)
      _check('org', org_param)

      payload = _generate_payload(data)
      return nil if payload.nil?

      uri = URI.parse(File.join(@options[:url], '/api/v2/write'))
      uri.query = URI.encode_www_form(bucket: bucket_param, org: org_param, precision: precision_param.to_s)

      _post(payload, uri)
    end

    private

    def _generate_payload(data)
      if data.nil?
        nil
      elsif data.is_a?(Point)
        data.to_line_protocol
      elsif data.is_a?(String)
        if data.empty?
          nil
        else
          data
        end
      elsif data.is_a?(Hash)
        _generate_payload(Point.from_hash(data))
      elsif data.respond_to? :map
        data.map do |item|
          _generate_payload(item)
        end.reject(&:nil?).join("\n".freeze)
      end
    end
  end
end
