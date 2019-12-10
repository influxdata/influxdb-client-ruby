# The MIT License
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the 'Software'), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require 'test_helper'

class PointTest < MiniTest::Test
  def test_to_line_protocol
    point_args = InfluxDB::Point.new(name: 'h2o',
                                     tags: { host: 'aws', region: 'us' },
                                     fields: { level: 5, saturation: '99%' }, time: 123)
    assert_equal 'h2o,host=aws,region=us level=5i,saturation="99%" 123', point_args.to_line_protocol

    point_hash = InfluxDB::Point.from_hash(name: 'h2o',
                                           tags: { host: 'aws', region: 'us' },
                                           fields: { level: 5, saturation: '99%' }, time: 123)
    assert_equal 'h2o,host=aws,region=us level=5i,saturation="99%" 123', point_hash.to_line_protocol
  end

  def test_measurement_escape
    point = InfluxDB::Point.new(name: 'h2 o', tags: { location: 'europe' }, fields: { level: 2 })
    assert_equal 'h2\\ o,location=europe level=2i', point.to_line_protocol

    point = InfluxDB::Point.new(name: 'h2,o', tags: { location: 'europe' }, fields: { level: 2 })
    assert_equal 'h2\\,o,location=europe level=2i', point.to_line_protocol
  end

  def test_tag_empty_key
    point = InfluxDB::Point.new(name: 'h2o', fields: { level: 2 }).add_tag('location', 'europe').add_tag('', 'warn')

    assert_equal 'h2o,location=europe level=2i', point.to_line_protocol
  end

  def test_tag_empty_value
    point = InfluxDB::Point.new(name: 'h2o', fields: { level: 2 }).add_tag('location', 'europe').add_tag('log', '')

    assert_equal 'h2o,location=europe level=2i', point.to_line_protocol
  end

  def test_override_tag_and_field
    point = InfluxDB::Point.new(name: 'h2o', fields: { level: '1' })
                           .add_tag('location', 'europe')
                           .add_tag('location', 'europe2')
                           .add_field(:level, 2)
                           .add_field(:level, 3)

    assert_equal 'h2o,location=europe2 level=3i', point.to_line_protocol
  end

  def test_field_types
    point = InfluxDB::Point.new(name: 'h2o')
                           .add_tag('tag_b', 'b')
                           .add_tag('tag_a', 'a')
                           .add_field('n1', -2)
                           .add_field('n2', 10)
                           .add_field('n3', 1_265_437_718_438_866_624_512)
                           .add_field('n4', 5.5)
                           .add_field('bool', true)
                           .add_field('string', 'string value')

    expected = 'h2o,tag_a=a,tag_b=b bool=true,n1=-2i,n2=10i,n3=1265437718438866624512i,n4=5.5,string="string value"'
    assert_equal expected, point.to_line_protocol
  end

  def test_field_null_value
    point = InfluxDB::Point.new(name: 'h2o')
                           .add_tag('location', 'europe')
                           .add_field('level', 2)
                           .add_field('warning', nil)

    assert_equal 'h2o,location=europe level=2i', point.to_line_protocol
  end

  def test_field_escape
    point = InfluxDB::Point.new(name: 'h2o')
                           .add_tag('location', 'europe')
                           .add_field('level', 'string esc\\ape value')

    assert_equal 'h2o,location=europe level="string esc\\\\ape value"', point.to_line_protocol

    point = InfluxDB::Point.new(name: 'h2o')
                           .add_tag('location', 'europe')
                           .add_field('level', 'string esc"ape value')

    assert_equal 'h2o,location=europe level="string esc\"ape value"', point.to_line_protocol
  end

  def test_time
    point = InfluxDB::Point.new(name: 'h2o')
                           .add_tag('location', 'europe')
                           .add_field('level', 2)
                           .time(123, InfluxDB::WritePrecision::NANOSECOND)

    assert_equal 'h2o,location=europe level=2i 123', point.to_line_protocol
  end

  def test_time_formatting
    time = Time.utc(2015, 10, 15, 8, 20, 15)

    point = InfluxDB::Point.new(name: 'h2o')
                           .add_tag('location', 'europe')
                           .add_field('level', 2)
                           .time(time, InfluxDB::WritePrecision::MILLISECOND)

    assert_equal 'h2o,location=europe level=2i 1444897215000', point.to_line_protocol

    point = InfluxDB::Point.new(name: 'h2o')
                           .add_tag('location', 'europe')
                           .add_field('level', 2)
                           .time(time, InfluxDB::WritePrecision::SECOND)

    assert_equal 'h2o,location=europe level=2i 1444897215', point.to_line_protocol

    point = InfluxDB::Point.new(name: 'h2o')
                           .add_tag('location', 'europe')
                           .add_field('level', 2)
                           .time(time, InfluxDB::WritePrecision::MICROSECOND)

    assert_equal 'h2o,location=europe level=2i 1444897215000000', point.to_line_protocol

    point = InfluxDB::Point.new(name: 'h2o')
                           .add_tag('location', 'europe')
                           .add_field('level', 2)
                           .time(time, InfluxDB::WritePrecision::NANOSECOND)

    assert_equal 'h2o,location=europe level=2i 1444897215000000000', point.to_line_protocol
  end

  def test_time_formatting_default
    time = Time.utc(2015, 10, 15, 8, 20, 15)

    point = InfluxDB::Point.new(name: 'h2o', time: time)
                           .add_tag('location', 'europe')
                           .add_field('level', 2)

    assert_equal 'h2o,location=europe level=2i 1444897215000000000', point.to_line_protocol

    point = InfluxDB::Point.new(name: 'h2o')
                           .add_tag('location', 'europe')
                           .add_field('level', 2)
                           .time(time, nil)

    assert_equal 'h2o,location=europe level=2i 1444897215000000000', point.to_line_protocol
  end

  def test_utf_8
    point = InfluxDB::Point.new(name: 'h2o')
                           .add_tag('location', 'Přerov')
                           .add_field('level', 2)
                           .time(123, InfluxDB::WritePrecision::NANOSECOND)

    assert_equal 'h2o,location=Přerov level=2i 123', point.to_line_protocol
  end

  def test_infinity_values
    point = InfluxDB::Point.new(name: 'h2o')
                           .add_tag('location', 'europe')
                           .add_field('infinity_constant', Float::INFINITY)
                           .add_field('infinity_positive', 1 / 0.0)
                           .add_field('infinity_negative', -1 / 0.0)
                           .add_field('level', 2)

    assert_equal 'h2o,location=europe level=2i', point.to_line_protocol
  end

  def test_only_infinity_values
    point = InfluxDB::Point.new(name: 'h2o')
                           .add_tag('location', 'europe')
                           .add_field('infinity_constant', Float::INFINITY)
                           .add_field('infinity_positive', 1 / 0.0)
                           .add_field('infinity_negative', -1 / 0.0)

    assert_nil point.to_line_protocol
  end
end
