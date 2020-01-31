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

require 'test_helper'

class QueryApiStreamTest < MiniTest::Test
  def test_length
    stream_iterator = StreamIterator.new
    assert_equal 2, stream_iterator.count
    assert_equal true, stream_iterator.closed
  end

  def test_iterate_enumerator
    stream_iterator = StreamIterator.new
    enumeration = stream_iterator.each
    assert_equal 'flux_record1', enumeration.next
    assert_equal 'flux_record2', enumeration.next

    error = assert_raises StopIteration do
      enumeration.next
    end

    assert_equal 'iteration reached an end', error.message
    assert_equal true, stream_iterator.closed
  end

  def test_iterate_enumerator2
    stream_iterator = StreamIterator.new
    enumeration = stream_iterator.to_enum
    assert_equal 'flux_record1', enumeration.next
    assert_equal 'flux_record2', enumeration.next

    error = assert_raises StopIteration do
      enumeration.next
    end

    assert_equal 'iteration reached an end', error.message
    assert_equal true, stream_iterator.closed
  end

  def test_iterate_block
    records = []

    stream_iterator = StreamIterator.new
    stream_iterator.each do |flux_record|
      records.push(flux_record)
    end

    assert_equal 2, records.count
    assert_equal 'flux_record1', records[0]
    assert_equal 'flux_record2', records[1]
    assert_equal true, stream_iterator.closed
  end

  def test_iterate_block_break
    records = []

    stream_iterator = StreamIterator.new
    stream_iterator.each do |flux_record|
      break if records.count > 0

      records.push(flux_record)
    end

    assert_equal 1, records.count
    assert_equal 'flux_record1', records[0]
    assert_equal true, stream_iterator.closed
  end

  def test_query_syntax
    records = []

    query(query: 'from >|', org: 'my-org').each do |flux_record|
      records.push(flux_record)
    end

    assert_equal 2, records.count
    assert_equal 'flux_record1', records[0]
    assert_equal 'flux_record2', records[1]
  end

  def query(*)
    StreamIterator.new
  end
end

class StreamIterator
  include Enumerable

  def initialize
    # Init CVS parser
    puts 'init http request...'
    @current = 1
    @closed = false
  end
  attr_reader :closed

  def each
    return enum_for(:each) unless block_given?

    while @current <= 2
      yield _parse_next_flux_record
      @current += 1
    end
    self
  ensure
    _close_connection
  end

  private

  def _parse_next_flux_record
    # Parse next line
    "flux_record#{@current}"
  end

  def _close_connection
    # Close CSV Parser and HTTP request
    @closed = true
    puts 'close http request...'
  end
end
