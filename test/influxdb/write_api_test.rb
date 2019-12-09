require 'test_helper'

class WriteApiTest < MiniTest::Test
  def test_required_arguments
    client = InfluxDB::Client.new('http://localhost:9999', 'my-token')
    write_api = client.create_write_api

    # precision
    assert_raises ArgumentError do
      write_api.write_record(record: {}, bucket: 'my-bucket', org: 'my-org')
    end
    # bucket
    assert_raises ArgumentError do
      write_api.write_record(record: {}, org: 'my-org', precision: InfluxDB::WritePrecision::NANOSECOND)
    end
    # org
    assert_raises ArgumentError do
      write_api.write_record(record: {}, bucket: 'my-bucket', precision: InfluxDB::WritePrecision::NANOSECOND)
    end
  end

  def test_default_arguments_
    client = InfluxDB::Client.new('http://localhost:9999', 'my-token',
                                  bucket: 'my-bucket',
                                  org: 'my-org',
                                  precision: InfluxDB::WritePrecision::NANOSECOND)
    write_api = client.create_write_api

    # without argument errors
    write_api.write_record(record: {})
  end
end
