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
require 'csv'

module InfluxDB2
  # This class represents Flux query error
  class FluxQueryError < StandardError
    def initialize(message, reference)
      super(message)
      @message = reference
    end
    attr_reader :response
  end

  # This class represents Flux query error
  class FluxCsvParserError < StandardError
    def initialize(message)
      super(message)
    end
  end

  # This class us used to construct FluxResult from CSV.
  class FluxCsvParser
    def initialize
      @tables = {}

      @table_index = 0
      @start_new_table = false
      @table = nil
      @parsing_state_error = false
    end
    attr_reader :tables

    def parse(response)
      tables = CSV.parse(response)

      tables.each do |csv|
        # Response has HTTP status ok, but response is error.
        next if csv.empty?

        if csv[1] == 'error' && csv[2] == 'reference'
          @parsing_state_error = true
          next
        end

        # Throw  InfluxException with error response
        if @parsing_state_error
          @error = csv[1]
          @reference_value = csv[2]
          raise FluxQueryError.new(error, @reference_value)
        end

        parse_line(csv)
      end
    end

    def parse_line(csv)
      token = csv[0]

      # start new table
      if token == '#datatype'
        # Return already parsed DataFrame
        @start_new_table = true
        @table = InfluxDB2::FluxTable.new
        @tables[:@table_index] = @table
        @table_index += 1
      elsif @table.nil?
        raise FluxCsvParserError, 'Unable to parse CSV response. FluxTable definition was not found.'
      end

      #  # datatype,string,long,dateTime:RFC3339,dateTime:RFC3339,dateTime:RFC3339,double,string,string,string
      if token == '#datatype'
        FluxCsvParser.add_data_types(@table, csv)

      elsif token == '#group'
        FluxCsvParser.add_groups(@table, csv)

      elsif token == '#default'
        FluxCsvParser.add_default_empty_values(@table, csv)
      end
    end

    def self.add_data_types(table, data_types)
      (1..data_types.length).each do |index|
        column_def = InfluxDB2::FluxColumn.new(index: index - 1, data_type: data_types[index])
        table.columns.push(column_def)
      end
    end

    def self.add_groups(table, csv)
      i = 1

      table.columns.each do |column|
        column.group = csv[i] == 'true'
        i += 1
      end
    end

    def self.add_default_empty_values(table, default_values)
      i = 1

      table.columns.each do |column|
        column.default_value = default_values[i]
        i += 1
      end
    end

    def self.add_column_names_and_tags(table, csv)
      i = 1

      table.columns.each do |column|
        column.label = csv[i]
        i += 1
      end
    end
  end
end
