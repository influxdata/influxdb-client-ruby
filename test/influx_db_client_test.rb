require "test_helper"

class InfluxDBClientTest < Minitest::Test
  def test_defined_version_number
    refute_nil ::InfluxDBClient::VERSION
  end

  def test_it_does_something_useful
    assert true
  end
end
