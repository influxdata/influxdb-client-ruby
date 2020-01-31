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
  # This class represents the table structure of the Flux CSV Response.
  # Ref: http://bit.ly/flux-spec#table
  class FluxTable
    def initialize
      @columns = []
      @records = []
    end
    attr_reader :columns, :records

    # A table's group key is subset of the entire columns dataset that assigned to the table.
    # As such, all records within a table will have the same values for each column that is part of the group key.
    def group_key
      columns = []

      @columns.each do |column|
        columns.push(column) if column.group
      end

      columns
    end
  end

  # A record is a tuple of values. Each record in the table represents a single point in the series.
  # Ref: http://bit.ly/flux-spec#record
  class FluxRecord
    # @param [Integer] table the index of table which contains the record
    # @param [Hash] values tuple of values
    def initialize(table, values: nil)
      @table = table
      @values = values || {}
    end
    attr_reader :table, :values
    attr_writer :table

    # @return [Time] the inclusive lower time bound of all records
    def start
      values['_start']
    end

    # @return [Time] the exclusive upper time bound of all records
    def stop
      values['_stop']
    end

    # @return [Time] the time of the record
    def time
      values['_time']
    end

    # @return [Object] the value of the record
    def value
      values['_value']
    end

    # @return [String] value with key "_field"
    def field
      values['_field']
    end

    # @return [String] value with key "_measurement"
    def measurement
      values['_measurement']
    end
  end

  # This class represents a column header specification of FluxTable.
  class FluxColumn
    def initialize(index: nil, label: nil, data_type: nil, group: nil, default_value: nil)
      @index = index
      @label = label
      @data_type = data_type
      @group = group
      @default_value = default_value
    end
    attr_reader :index, :label, :data_type, :group, :default_value
    attr_writer :index, :label, :data_type, :group, :default_value
  end
end
