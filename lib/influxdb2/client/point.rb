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
  DEFAULT_WRITE_PRECISION = WritePrecision::NANOSECOND
  ESCAPE_KEY_LIST = ['\\'.freeze, ','.freeze, ' '.freeze, '='.freeze].freeze
  ESCAPE_MEASUREMENT_LIST = ['\\'.freeze, ','.freeze, ' '.freeze].freeze
  REPLACE_KEY_LIST = { "\n".freeze => '\n'.freeze, "\r".freeze => '\r'.freeze, "\t".freeze => '\t'.freeze }.freeze
  ESCAPE_VALUE_LIST = ['\\'.freeze, '"'.freeze].freeze

  # Point defines the values that will be written to the database.
  # Ref: http://bit.ly/influxdata-point
  class Point
    # Create DataPoint instance for specified measurement name.
    #
    # @example InfluxDB2::Point.new(name: "h2o",
    #   tags: {host: 'aws', region: 'us'},
    #   fields: {level: 5, saturation: "99%"},
    #   time: 123)
    #
    # @param [String] name the measurement name for the point.
    # @param [Hash] tags the tag set for the point
    # @param [Hash] fields the fields for the point
    # @param [Integer] time the timestamp for the point
    # @param [WritePrecision] precision the precision for the unix timestamps within the body line-protocol
    def initialize(name:, tags: nil, fields: nil, time: nil, precision: DEFAULT_WRITE_PRECISION)
      @name = name
      @tags = tags || {}
      @fields = fields || {}
      @time = time
      @precision = precision
    end
    attr_reader :precision

    # Create DataPoint instance from specified data.
    #
    # @example Point.fromHash({
    #   name: 'cpu',
    #   tags: { host: 'server_nl', regios: 'us' },
    #   fields: {internal: 5, external: 6},
    #   time: 1422568543702900257
    # })
    #
    # @param [Hash] data
    def self.from_hash(data)
      obj = new(name: data[:name], tags: data[:tags], fields: data[:fields], time: data[:time])
      obj
    end

    # Adds or replaces a tag value for a point.
    #
    # @example InfluxDB2::Point.new(name: "h2o")
    #   .add_tag("location", "europe")
    #   .add_field("level", 2)
    #
    # @param [Object] key the tag name
    # @param [Object] value the tag value
    def add_tag(key, value)
      @tags[key] = value
      self
    end

    # Adds or replaces a field value for a point.
    #
    # @example InfluxDB2::Point.new(name: "h2o")
    #   .add_tag("location", "europe")
    #   .add_field("level", 2)
    #
    # @param [Object] key the field name
    # @param [Object] value the field value
    def add_field(key, value)
      @fields[key] = value
      self
    end

    # Updates the timestamp for the point.
    #
    # @example InfluxDB2::Point.new(name: "h2o")
    #   .add_tag("location", "europe")
    #   .add_field("level", 2)
    #   .time(Time.new(2015, 10, 15, 8, 20, 15), InfluxDB2::WritePrecision::MILLISECOND)
    #
    # @example InfluxDB2::Point.new(name: "h2o")
    #   .add_tag("location", "europe")
    #   .add_field("level", 2)
    #   .time(123, InfluxDB2::WritePrecision::NANOSECOND)
    #
    # @param [Object] time the timestamp
    # @param [WritePrecision] precision the timestamp precision
    def time(time, precision)
      @time = time
      @precision = precision
      self
    end

    # If there is no field then return nil.
    #
    # @return a string representation of the point
    def to_line_protocol
      line_protocol = ''
      measurement = _escape_key(@name || '', ESCAPE_MEASUREMENT_LIST)

      line_protocol << measurement

      tags = _escape_tags
      line_protocol << ",#{tags}" unless tags.empty?
      line_protocol << ' '.freeze if line_protocol[-1] == '\\'

      fields = _escape_fields
      return nil if fields.empty?

      line_protocol << " #{fields}" if fields
      timestamp = _escape_time
      line_protocol << " #{timestamp}" if timestamp

      line_protocol
    end

    private

    def _escape_tags
      return if @tags.nil?

      @tags.sort.to_h.map do |k, v|
        key = _escape_key(k.to_s)
        value = _escape_key(v.to_s)
        if key.empty? || value.empty?
          nil
        else
          "#{key}=#{value}"
        end
      end.reject(&:nil?).join(','.freeze)
    end

    def _escape_fields
      return if @fields.nil?

      @fields.sort.to_h.map do |k, v|
        key = _escape_key(k.to_s)
        value = _escape_value(v)
        if key.empty? || value.empty?
          nil
        else
          "#{key}=#{value}"
        end
      end.reject(&:nil?).join(','.freeze)
    end

    def _escape_key(value, escape_list = ESCAPE_KEY_LIST)
      result = value.dup
      escape_list.each do |ch|
        result = result.gsub(ch) { "\\#{ch}" }
      end
      REPLACE_KEY_LIST.keys.each do |ch|
        result = result.gsub(ch) { REPLACE_KEY_LIST[ch] }
      end
      result
    end

    def _escape_value(value)
      if value.nil?
        ''
      elsif value.is_a?(String)
        result = value.dup
        ESCAPE_VALUE_LIST.each do |ch|
          result = result.gsub(ch) { "\\#{ch}" }
        end
        '"'.freeze + result + '"'.freeze
      elsif value.is_a?(Integer)
        "#{value}i"
      elsif [Float::INFINITY, -Float::INFINITY].include?(value)
        ''
      else
        value.to_s
      end
    end

    def _escape_time
      if @time.nil?
        nil
      elsif @time.is_a?(Integer)
        @time.to_s
      elsif @time.is_a?(Float)
        @time.round.to_s
      elsif @time.is_a?(Time)
        nano_seconds = @time.to_i * 1e9
        nano_seconds += @time.tv_nsec
        case @precision || DEFAULT_WRITE_PRECISION
        when InfluxDB2::WritePrecision::MILLISECOND then
          (nano_seconds / 1e6).round
        when InfluxDB2::WritePrecision::SECOND then
          (nano_seconds / 1e9).round
        when InfluxDB2::WritePrecision::MICROSECOND then
          (nano_seconds / 1e3).round
        when InfluxDB2::WritePrecision::NANOSECOND then
          nano_seconds.round
        end
      else
        @time.to_s
      end
    end
  end
end
