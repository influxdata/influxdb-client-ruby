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
  class TestWriteApi < WriteApi
    @metrics = []

    def self.metrics
      @metrics ||= []
    end

    def self.metrics=(value)
      @metrics = value
    end

    # Write test data into specified Bucket.
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
    #   precision: InfluxDB2::WritePrecision::NANOSECOND,
    #   bucket: 'my-bucket',
    #   org: 'my-org'
    # )
    #
    # @example write(data: 'h2o,location=west value=33i 15')
    #
    # @example point = InfluxDB2::Point.new(name: 'h2o')
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

      _add_default_tags(data)

      return nil if data.nil?

      self.class.metrics << { data: data, precision: precision_param, bucket: bucket_param, org: org_param }
    end

    # @return [ true ] Always true.
    def close!
      true
    end

    # @param [String] payload data as String
    # @param [WritePrecision] precision The precision for the unix timestamps within the body line-protocol
    # @param [String] bucket specifies the destination bucket for writes
    # @param [String] org specifies the destination organization for writes
    def write_raw(payload, precision: nil, bucket: nil, org: nil)
    end
  end
end
