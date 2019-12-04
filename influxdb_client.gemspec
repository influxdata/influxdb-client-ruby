lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "influxdb_client/version"

Gem::Specification.new do |spec|
  spec.name          = "influxdb_client"
  spec.version       = InfluxDBClient::VERSION
  spec.authors       = ["Jakub Bednar"]
  spec.email         = ["jakub.bednar@gmail.com"]

  spec.summary       = "Ruby library for InfluxDB 2."
  spec.description   = "This is the official Ruby library for InfluxDB 2."
  spec.homepage      = "https://github.com/bonitoo-io/influxdb-client-ruby"
  spec.license       = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "git@github.com:bonitoo-io/influxdb-client-ruby.git"
  spec.metadata["changelog_uri"] = "https://raw.githubusercontent.com/bonitoo-io/influxdb-client-ruby/master/CHANGELOG.md"

  spec.files         = `git ls-files`.split($/)
  spec.test_files    = spec.files.grep(%r{^(test|spec|features|smoke)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"
end
