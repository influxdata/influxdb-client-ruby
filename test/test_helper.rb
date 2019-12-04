$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'influxdb_client'

require 'minitest/autorun'
require 'minitest/reporters'
Minitest::Reporters.use!
