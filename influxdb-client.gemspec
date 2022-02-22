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

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'influxdb2/client/version'

# noinspection DuplicatedCode
Gem::Specification.new do |spec|
  spec.name          = 'influxdb-client'
  spec.version       = ENV['CIRCLE_BUILD_NUM'] ? "#{InfluxDB2::VERSION}-#{ENV['CIRCLE_BUILD_NUM']}" : InfluxDB2::VERSION
  spec.authors       = ['Jakub Bednar']
  spec.email         = ['jakub.bednar@gmail.com']

  spec.summary       = 'Ruby library for InfluxDB 2.'
  spec.description   = 'This is the official Ruby library for InfluxDB 2.'
  spec.homepage      = 'https://github.com/influxdata/influxdb-client-ruby'
  spec.license       = 'MIT'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/influxdata/influxdb-client-ruby'
  spec.metadata['changelog_uri'] = 'https://raw.githubusercontent.com/influxdata/influxdb-client-ruby/master/CHANGELOG.md'

  spec.files = Dir.glob('lib/**/*')
  spec.files += %w[influxdb-client.gemspec LICENSE README.md CHANGELOG.md Rakefile]
  spec.test_files = Dir.glob('test/**/*')
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 2.2.0'

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'minitest', '~> 5.0'
  spec.add_development_dependency 'minitest-reporters', '~> 1.4'
  spec.add_development_dependency 'rake', '~> 12.3'
  spec.add_development_dependency 'rubocop', '~> 0.66.0'
  spec.add_development_dependency 'simplecov-cobertura', '~> 1.4.2'
  spec.add_development_dependency 'webmock', '~> 3.7'
end
