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
require 'influxdb2/client/helpers/minitest_helper'

class AssertMetricTest < Minitest::Test
  def test_assert_metric_passes
    build_test_write_api.write(data: 'h2o,location=west value=33i 15')

    assert_metric(
      data: 'h2o,location=west value=33i 15',
      precision: InfluxDB2::WritePrecision::NANOSECOND,
      bucket: 'my-bucket',
      org: 'my-org',
    )
  end

  def test_assert_metric_with_block_passes
    assert_metric(
      data: 'h2o,location=west value=33i 15',
      precision: InfluxDB2::WritePrecision::NANOSECOND,
      bucket: 'my-bucket',
      org: 'my-org',
    ) do
      build_test_write_api.write(data: 'h2o,location=west value=33i 15')
    end
  end

  def test_assert_metric_with_block_fails
    build_test_write_api.write(data: 'h2o,location=west value=33i 15')

    assert_raises(Minitest::Assertion) do
      assert_metric(
        data: 'h2o,location=west value=33i 15',
        precision: InfluxDB2::WritePrecision::NANOSECOND,
        bucket: 'my-bucket',
        org: 'my-org',
      ) do
        # no-op
      end
    end
  end

  def test_assert_metric_fails
    assert_raises(Minitest::Assertion) do
      assert_metric(
        data: 'h2o,location=west value=33i 15',
        precision: InfluxDB2::WritePrecision::NANOSECOND,
        bucket: 'my-bucket',
        org: 'my-org',
      )
    end
  end

  def test_assert_metric_with_hash_passes
    build_test_write_api.write(data: {
        name: 'h2o',
        tags: { region: 'us', host: 'aws' },
        fields: { level: 5, saturation: '99%' }, 
        time: 123 
      },
    )

    assert_metric(
      data: {
        name: 'h2o',
        tags: { region: 'us', host: 'aws' },
        fields: { level: 5, saturation: '99%' }, 
        time: 123 
      },
      precision: InfluxDB2::WritePrecision::NANOSECOND,
      bucket: 'my-bucket',
      org: 'my-org',
    )
  end

  private

  def build_test_write_api(bucket: 'my-bucket', org: 'my-org', precision: InfluxDB2::WritePrecision::NANOSECOND)
    env = InfluxDB2::Environment.new('INFLUXDB_ENV' => 'test')
    client = InfluxDB2::Client.new(
      'http://localhost:8086',
      'my-token',
      bucket: bucket,
      org: org,
      env: env,
      precision: precision
    ).create_write_api
  end
end
