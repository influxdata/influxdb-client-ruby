# influxdb-client-ruby

[![CircleCI](https://circleci.com/gh/bonitoo-io/influxdb-client-ruby.svg?style=svg)](https://circleci.com/gh/bonitoo-io/influxdb-client-ruby)
[![codecov](https://codecov.io/gh/bonitoo-io/influxdb-client-ruby/branch/master/graph/badge.svg)](https://codecov.io/gh/bonitoo-io/influxdb-client-ruby)
[![Gem Version](https://badge.fury.io/rb/influxdb_client.svg)](https://badge.fury.io/rb/influxdb_client)
[![License](https://img.shields.io/github/license/bonitoo-io/influxdb-client-ruby.svg)](https://github.com/bonitoo-io/influxdb-client-ruby/blob/master/LICENSE)
[![GitHub issues](https://img.shields.io/github/issues-raw/bonitoo-io/influxdb-client-ruby.svg)](https://github.com/bonitoo-io/influxdb-client-ruby/issues)
[![GitHub pull requests](https://img.shields.io/github/issues-pr-raw/bonitoo-io/influxdb-client-ruby.svg)](https://github.com/bonitoo-io/influxdb-client-ruby/pulls)

This repository contains the reference Ruby client for the InfluxDB 2.0.

### Note: This library is for use with InfluxDB 2.x. For connecting to InfluxDB 1.x instances, please use the [influxdb-ruby](https://github.com/influxdata/influxdb-ruby) client.

## Installation

The InfluxDB 2 client is bundled as a gem and is hosted on [Rubygems](https://rubygems.org/gems/mongo).

### Install the Gem

The client can be installed manually or with bundler.

To install the client gem manually:

```
gem install influxdb_client -v 1.0.0.alpha
```

## Usage

### Creating a client

Use **InfluxDB::Client** to create a client connected to a running InfluxDB 2 instance.

```ruby
client = InfluxDB::Client.new(url: 'http://localhost:9999', token: 'my-token')
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/bonitoo-io/influxdb-client-ruby.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
