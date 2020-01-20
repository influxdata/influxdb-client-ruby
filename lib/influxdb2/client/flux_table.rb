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

# This class represents the table structure of the Flux CSV Response.
# Ref: http://bit.ly/flux-spec#table
class FluxTable

  def initialize
    @columns = {}
    @records = {}
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

end

# This class represents a column header specification of FluxTable.
class FluxColumn

  def initialize

  end

end