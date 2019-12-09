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

module InfluxDB
  class WritePrecision
    MILLISECOND = 'ms'.freeze
    SECOND = 's'.freeze
    MICROSECOND = 'us'.freeze
    NANOSECOND = 'ns'.freeze
  end

  # Write time series data into InfluxDB.
  #
  class WriteApi
    # @param [Hash] options The options to be used by the client.
    def initialize(options:)
      @options = options
    end

    # Write DataPoint into specified Bucket.
    #
    # @example write_record(record:
    #   {
    #     series: 'cpu',
    #     tags: { host: 'server_nl', regios: 'us' },
    #     values: {internal: 5, external: 6},
    #     timestamp: 1422568543702900257
    #   },
    #   bucket: 'my-bucket',
    #   org: 'my-org'
    # )
    #
    # @param [Hash] record DataPoint to write into InfluxDB
    # @param [WritePrecision] precision the precision for the unix timestamps within the body line-protocol
    # @param [String] bucket specifies the destination bucket for writes
    # @param [String] org specifies the destination organization for writes
    def write_record(record:, precision: nil, bucket: nil, org: nil)
      write_records(records: [record], precision: precision, bucket: bucket, org: org)
    end

    # Write DataPoints into specified Bucket.
    #
    # @example write_records(records:
    #   [
    #     {
    #       series: 'cpu', tags: { host: 'server_nl', regios: 'us' },
    #       values: {internal: 5, external: 6}, timestamp: 1422568543702900257
    #     },
    #     {series: 'gpu', values: {value: 0.9999}}
    #   ],
    #   bucket: 'my-bucket',
    #   org: 'my-org'
    # )
    #
    # @param [Array[Hash]] records DataPoints to write into InfluxDB
    # @param [WritePrecision] precision The precision for the unix timestamps within the body line-protocol
    # @param [String] bucket specifies the destination bucket for writes
    # @param [String] org specifies the destination organization for writes
    def write_records(records:, precision: nil, bucket: nil, org: nil)
      precision_param = precision || @options[:precision]
      bucket_param = bucket || @options[:bucket]
      org_param = org || @options[:org]
      _check('precision', precision_param)
      _check('bucket', bucket_param)
      _check('org', org_param)

      puts records
    end

    private

    def _check(key, value)
      raise ArgumentError, "The '#{key}' should be defined as argument or default option: #{@options}" if value.nil?
    end
  end
end
