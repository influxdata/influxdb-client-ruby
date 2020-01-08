# influxdb-client-ruby

[![CircleCI](https://circleci.com/gh/bonitoo-io/influxdb-client-ruby.svg?style=svg)](https://circleci.com/gh/bonitoo-io/influxdb-client-ruby)
[![codecov](https://codecov.io/gh/bonitoo-io/influxdb-client-ruby/branch/master/graph/badge.svg)](https://codecov.io/gh/bonitoo-io/influxdb-client-ruby)
[![Gem Version](https://badge.fury.io/rb/influxdb-client.svg)](https://badge.fury.io/rb/influxdb-client)
[![License](https://img.shields.io/github/license/bonitoo-io/influxdb-client-ruby.svg)](https://github.com/bonitoo-io/influxdb-client-ruby/blob/master/LICENSE)
[![GitHub issues](https://img.shields.io/github/issues-raw/bonitoo-io/influxdb-client-ruby.svg)](https://github.com/bonitoo-io/influxdb-client-ruby/issues)
[![GitHub pull requests](https://img.shields.io/github/issues-pr-raw/bonitoo-io/influxdb-client-ruby.svg)](https://github.com/bonitoo-io/influxdb-client-ruby/pulls)

This repository contains the reference Ruby client for the InfluxDB 2.0.

#### Note: This library is for use with InfluxDB 2.x. For connecting to InfluxDB 1.x instances, please use the [influxdb-ruby](https://github.com/influxdata/influxdb-ruby) client.
#### Disclaimer: This library is a work in progress and should not be considered production ready yet.

## Installation

The InfluxDB 2 client is bundled as a gem and is hosted on [Rubygems](https://rubygems.org/gems/influxdb-client).

### Install the Gem

The client can be installed manually or with bundler.

To install the client gem manually:

```
gem install influxdb-client --pre
```

## Usage

### Creating a client

Use **InfluxDB::Client** to create a client connected to a running InfluxDB 2 instance.

```ruby
client = InfluxDB::Client.new('https://localhost:9999', 'my-token')
```

#### Client Options

| Option | Description | Type | Default |
|---|---|---|---|
| bucket | Default destination bucket for writes | String | none |
| org | Default organization bucket for writes | String | none |
| precision | Default precision for the unix timestamps within the body line-protocol | String | none |
| open_timeout | Number of seconds to wait for the connection to open | Integer | 10 |
| write_timeout | Number of seconds to wait for one block of data to be written | Integer | 10 |
| read_timeout | Number of seconds to wait for one block of data to be read | Integer | 10 |
| max_redirect_count | Maximal number of followed HTTP redirects | Integer | 10 |
| use_ssl | Turn on/off SSL for HTTP communication | bool | true |

```ruby
client = InfluxDB::Client.new('https://localhost:9999', 'my-token',
  bucket: 'my-bucket',
  org: 'my-org',
  precision: InfluxDB::WritePrecision::NANOSECOND)
```

### Writing data

```ruby
client = InfluxDB::Client.new('https://localhost:9999', 'my-token',
                              bucket: 'my-bucket',
                              org: 'my-org',
                              precision: InfluxDB::WritePrecision::NANOSECOND)

write_api = client.create_write_api
write_api.write(data: 'h2o,location=west value=33i 15')
```

#### Time precision

Configure default time precision:
```ruby
client = InfluxDB::Client.new('https://localhost:9999', 'my-token',
                              bucket: 'my-bucket',
                              org: 'my-org',
                              precision: InfluxDB::WritePrecision::NANOSECOND)
```

Configure precision per write:
```ruby
client = InfluxDB::Client.new('https://localhost:9999', 'my-token',
                                  bucket: 'my-bucket',
                                  org: 'my-org')

write_api = client.create_write_api
write_api.write(data: 'h2o,location=west value=33i 15', precision: InfluxDB::WritePrecision::SECOND)
```

Allowed values for precision are:
- `InfluxDB::WritePrecision::NANOSECOND` for nanosecond
- `InfluxDB::WritePrecision::MICROSECOND` for microsecond
- `InfluxDB::WritePrecision::MILLISECOND` for millisecond
- `InfluxDB::WritePrecision::SECOND` for second

#### Configure destination

Default `bucket` and `organization` destination are configured via `InfluxDB::Client`:
```ruby
client = InfluxDB::Client.new('https://localhost:9999', 'my-token',
                              bucket: 'my-bucket',
                              org: 'my-org')
```

but there is also possibility to override configuration per write:

```ruby
client = InfluxDB::Client.new('https://localhost:9999', 'my-token')

write_api = client.create_write_api
write_api.write(data: 'h2o,location=west value=33i 15', bucket: 'production-data', org: 'customer-1')
```

#### Data format

The data could be written as:

1. `String` that is formatted as a InfluxDB's line protocol
1. `Hash` with keys: name, tags, fields and time
1. [Data Point](https://github.com/bonitoo-io/influxdb-client-ruby/blob/master/lib/influxdb/client/point.rb#L28) structure
1. `Array` of above items

```ruby
client = InfluxDB::Client.new('https://localhost:9999', 'my-token',
                              bucket: 'my-bucket',
                              org: 'my-org',
                              precision: InfluxDB::WritePrecision::NANOSECOND)

point = InfluxDB::Point.new(name: 'h2o')
                       .add_tag('location', 'europe')
                       .add_field('level', 2)

hash = { name: 'h2o',
         tags: { host: 'aws', region: 'us' },
         fields: { level: 5, saturation: '99%' }, time: 123 }

write_api = client.create_write_api
write_api.write(data: ['h2o,location=west value=33i 15', point, hash])
```

## Local tests

```
brew install wget # on a mac, if not yet installed!
bin/influxdb-restart.sh
rake test
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/bonitoo-io/influxdb-client-ruby.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
