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
require_relative 'worker'

module InfluxDB2
  module WriteType
    SYNCHRONOUS = 1
    BATCHING = 2
  end

  # Creates write api configuration.
  #
  class WriteOptions
    # @param [WriteType] write_type: methods of write (batching, synchronous)
    # @param [Integer] batch_size: the number of data point to collect in batch
    # @param [Integer] flush_interval: flush data at least in this interval
    # @param [Integer] retry_interval: number of milliseconds to retry unsuccessful write.
    #   The retry interval is used when the InfluxDB server does not specify "Retry-After" header.
    # @param [Integer] jitter_interval: the number of milliseconds to increase the batch flush interval
    #   by a random amount
    def initialize(write_type: WriteType::SYNCHRONOUS, batch_size: 1_000, flush_interval: 1_000, retry_interval: 1_000,
                   jitter_interval: 0)
      _check_not_negative('batch_size', batch_size)
      _check_not_negative('flush_interval', flush_interval)
      _check_not_negative('retry_interval', retry_interval)
      _check_positive('jitter_interval', jitter_interval)
      @write_type = write_type
      @batch_size = batch_size
      @flush_interval = flush_interval
      @retry_interval = retry_interval
      @jitter_interval = jitter_interval
    end

    attr_reader :write_type, :batch_size, :flush_interval, :retry_interval, :jitter_interval

    def _check_not_negative(key, value)
      raise ArgumentError, "The '#{key}' should be positive or zero, but is: #{value}" if value <= 0
    end

    def _check_positive(key, value)
      raise ArgumentError, "The '#{key}' should be positive number, but is: #{value}" if value < 0
    end
  end

  SYNCHRONOUS = InfluxDB2::WriteOptions.new(write_type: WriteType::SYNCHRONOUS)

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
    # @param [WriteOptions] write_options Write api configuration.
    def initialize(options:, write_options: SYNCHRONOUS)
      super(options: options)
      @write_options = write_options
      @closed = false
    end
    attr_reader :closed

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

      payload = _generate_payload(data, bucket: bucket_param, org: org_param, precision: precision_param)
      return nil if payload.nil?

      if WriteType::BATCHING == @write_options.write_type
        _worker.push(payload)
      else
        write_raw(payload, precision: precision_param, bucket: bucket_param, org: org_param)
      end
    end

    # @return [ true ] Always true.
    def close!
      _worker.flush_all unless _worker.nil?
      @closed = true
      true
    end

    # @param [String] payload data as String
    # @param [WritePrecision] precision The precision for the unix timestamps within the body line-protocol
    # @param [String] bucket specifies the destination bucket for writes
    # @param [String] org specifies the destination organization for writes
    def write_raw(payload, precision: nil, bucket: nil, org: nil)
      precision_param = precision || @options[:precision]
      bucket_param = bucket || @options[:bucket]
      org_param = org || @options[:org]
      _check('precision', precision_param)
      _check('bucket', bucket_param)
      _check('org', org_param)

      return nil unless payload.instance_of?(String) || payload.empty?

      uri = URI.parse(File.join(@options[:url], '/api/v2/write'))
      uri.query = URI.encode_www_form(bucket: bucket_param, org: org_param, precision: precision_param.to_s)

      _post_text(payload, uri)
    end

    # Item for batching queue
    class BatchItem
      def initialize(key, data)
        @key = key
        @data = data
      end
      attr_reader :key, :data
    end

    # Key for batch item
    class BatchItemKey
      def initialize(bucket, org, precision = DEFAULT_WRITE_PRECISION)
        @bucket = bucket
        @org = org
        @precision = precision
      end
      attr_reader :bucket, :org, :precision

      def ==(other)
        @bucket == other.bucket && @org == other.org && @precision == other.precision
      end

      alias eql? ==

      def hash
        @bucket.hash ^ @org.hash ^ @precision.hash # XOR
      end
    end

    private

    WORKER_MUTEX = Mutex.new
    def _worker
      return nil unless @write_options.write_type == WriteType::BATCHING

      return @worker if @worker

      WORKER_MUTEX.synchronize do
        # this return is necessary because the previous mutex holder
        # might have already assigned the @worker
        return @worker if @worker

        @worker = Worker.new(self, @write_options)
      end
    end

    def _generate_payload(data, precision: nil, bucket: nil, org: nil)
      if data.nil?
        nil
      elsif data.is_a?(Point)
        _generate_payload(data.to_line_protocol, bucket: bucket, org: org, precision: data.precision ||
            DEFAULT_WRITE_PRECISION)
      elsif data.is_a?(String)
        if data.empty?
          nil
        elsif @write_options.write_type == WriteType::BATCHING
          BatchItem.new(BatchItemKey.new(bucket, org, precision), data)
        else
          data
        end
      elsif data.is_a?(Hash)
        _generate_payload(Point.from_hash(data), bucket: bucket, org: org, precision: precision)
      elsif data.respond_to? :map
        payloads = data.map do |item|
          _generate_payload(item, bucket: bucket, org: org, precision: precision)
        end.reject(&:nil?)
        if @write_options.write_type == WriteType::BATCHING
          payloads
        else
          payloads.join("\n".freeze)
        end
      end
    end
  end
end
