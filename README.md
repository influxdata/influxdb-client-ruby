# influxdb-client-ruby

[![CircleCI](https://circleci.com/gh/influxdata/influxdb-client-ruby.svg?style=svg)](https://circleci.com/gh/influxdata/influxdb-client-ruby)
[![codecov](https://codecov.io/gh/influxdata/influxdb-client-ruby/branch/master/graph/badge.svg)](https://codecov.io/gh/influxdata/influxdb-client-ruby)
[![Gem Version](https://badge.fury.io/rb/influxdb-client.svg)](https://badge.fury.io/rb/influxdb-client)
[![License](https://img.shields.io/github/license/influxdata/influxdb-client-ruby.svg)](https://github.com/influxdata/influxdb-client-ruby/blob/master/LICENSE)
[![GitHub issues](https://img.shields.io/github/issues-raw/influxdata/influxdb-client-ruby.svg)](https://github.com/influxdata/influxdb-client-ruby/issues)
[![GitHub pull requests](https://img.shields.io/github/issues-pr-raw/influxdata/influxdb-client-ruby.svg)](https://github.com/influxdata/influxdb-client-ruby/pulls)
[![Slack Status](https://img.shields.io/badge/slack-join_chat-white.svg?logo=slack&style=social)](https://www.influxdata.com/slack)

This repository contains the reference Ruby client for the InfluxDB 2.0.

#### Note: Use this client library with InfluxDB 2.x and InfluxDB 1.8+ ([see details](#influxdb-18-api-compatibility)). For connecting to InfluxDB 1.7 or earlier instances, use the [influxdb-ruby](https://github.com/influxdata/influxdb-ruby) client library.

## Installation

The InfluxDB 2 client is bundled as a gem and is hosted on [Rubygems](https://rubygems.org/gems/influxdb-client).

### Install the Gem

The client can be installed manually or with bundler.

To install the client gem manually:

```
gem install influxdb-client -v 1.3.0
```

## Usage

### Creating a client

Use **InfluxDB::Client** to create a client connected to a running InfluxDB 2 instance.

```ruby
client = InfluxDB2::Client.new('https://localhost:9999', 'my-token')
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
client = InfluxDB2::Client.new('https://localhost:9999', 'my-token',
  bucket: 'my-bucket',
  org: 'my-org',
  precision: InfluxDB2::WritePrecision::NANOSECOND)
```

### Queries

The result retrieved by [QueryApi](https://github.com/influxdata/influxdb-client-ruby/blob/master/lib/influxdb2/client/query_api.rb) could be formatted as a:

   1. Raw query response
   2. Flux data structure: [FluxTable, FluxColumn and FluxRecord](https://github.com/influxdata/influxdb-client-ruby/blob/master/lib/influxdb2/client/flux_table.rb)
   3. Stream of [FluxRecord](https://github.com/influxdata/influxdb-client-ruby/blob/master/lib/influxdb2/client/flux_table.rb)

#### Query raw

Synchronously executes the Flux query and return result as unprocessed String
```ruby
client = InfluxDB2::Client.new('https://localhost:9999', 'my-token',
                              bucket: 'my-bucket',
                              org: 'my-org')

query_api = client.create_query_api
result = query_api.query_raw(query: 'from(bucket:"' + bucket + '") |> range(start: 1970-01-01T00:00:00.000000001Z) |> last()')
```
#### Synchronous query
Synchronously executes the Flux query and return result as a Array of [FluxTables](https://github.com/influxdata/influxdb-client-ruby/blob/master/lib/influxdb2/client/flux_table.rb)
```ruby
client = InfluxDB2::Client.new('https://localhost:9999', 'my-token',
                              bucket: 'my-bucket',
                              org: 'my-org')

query_api = client.create_query_api
result = query_api.query(query: 'from(bucket:"' + bucket + '") |> range(start: 1970-01-01T00:00:00.000000001Z) |> last()')
```

#### Query stream
Synchronously executes the Flux query and return stream of [FluxRecord](https://github.com/influxdata/influxdb-client-ruby/blob/master/lib/influxdb2/client/flux_table.rb)
```ruby
client = InfluxDB2::Client.new('https://localhost:9999', 'my-token',
                              bucket: 'my-bucket',
                              org: 'my-org')

query_api = client.create_query_api

query = 'from(bucket: "my-bucket") |> range(start: -10m, stop: now()) ' \
      "|> filter(fn: (r) => r._measurement == \"#{measurement}\")"

query_api.query_stream(query: query).each do |record|
  puts record.to_s
end
```

### Writing data
The [WriteApi](https://github.com/influxdata/influxdb-client-ruby/blob/master/lib/influxdb2/client/write_api.rb) supports synchronous and batching writes into InfluxDB 2.0. In default api uses synchronous write. To enable batching you can use WriteOption.

```ruby
client = InfluxDB2::Client.new('https://localhost:9999', 'my-token',
                              bucket: 'my-bucket',
                              org: 'my-org',
                              precision: InfluxDB2::WritePrecision::NANOSECOND)

write_api = client.create_write_api
write_api.write(data: 'h2o,location=west value=33i 15')
```

#### Batching
The writes are processed in batches which are configurable by `WriteOptions`:

| Property | Description | Default Value |
| --- | --- | --- |
| batchSize | the number of data point to collect in batch | 1000 |
| flushInterval | the number of milliseconds before the batch is written | 1000 |
| retry_interval | the number of milliseconds to retry unsuccessful write. The retry interval is used when the InfluxDB server does not specify "Retry-After" header. | 1000 |
| jitter_interval | the number of milliseconds to increase the batch flush interval by a random amount | 0 |

```ruby
write_options = InfluxDB2::WriteOptions.new(write_type: InfluxDB2::WriteType::BATCHING,
                                            batch_size: 10, flush_interval: 5_000)
client = InfluxDB2::Client.new('http://localhost:9999',
                               'my-token',
                               bucket: 'my-bucket',
                               org: 'my-org',
                               precision: InfluxDB2::WritePrecision::NANOSECOND,
                               use_ssl: false)

write_api = client.create_write_api(write_options: write_options)
write_api.write(data: 'h2o,location=west value=33i 15')
```

#### Time precision

Configure default time precision:
```ruby
client = InfluxDB2::Client.new('https://localhost:9999', 'my-token',
                              bucket: 'my-bucket',
                              org: 'my-org',
                              precision: InfluxDB2::WritePrecision::NANOSECOND)
```

Configure precision per write:
```ruby
client = InfluxDB2::Client.new('https://localhost:9999', 'my-token',
                                  bucket: 'my-bucket',
                                  org: 'my-org')

write_api = client.create_write_api
write_api.write(data: 'h2o,location=west value=33i 15', precision: InfluxDB2::WritePrecision::SECOND)
```
Allowed values for precision are:
- `InfluxDB::WritePrecision::NANOSECOND` for nanosecond
- `InfluxDB::WritePrecision::MICROSECOND` for microsecond
- `InfluxDB::WritePrecision::MILLISECOND` for millisecond
- `InfluxDB::WritePrecision::SECOND` for second

#### Configure destination

Default `bucket` and `organization` destination are configured via `InfluxDB::Client`:
```ruby
client = InfluxDB2::Client.new('https://localhost:9999', 'my-token',
                              bucket: 'my-bucket',
                              org: 'my-org')
```

but there is also possibility to override configuration per write:

```ruby
client = InfluxDB2::Client.new('https://localhost:9999', 'my-token')

write_api = client.create_write_api
write_api.write(data: 'h2o,location=west value=33i 15', bucket: 'production-data', org: 'customer-1')
```

#### Data format

The data could be written as:

1. `String` that is formatted as a InfluxDB's line protocol
1. `Hash` with keys: name, tags, fields and time
1. [Data Point](https://github.com/influxdata/influxdb-client-ruby/blob/master/lib/influxdb/client/point.rb#L28) structure
1. `Array` of above items

```ruby
client = InfluxDB2::Client.new('https://localhost:9999', 'my-token',
                              bucket: 'my-bucket',
                              org: 'my-org',
                              precision: InfluxDB2::WritePrecision::NANOSECOND)

point = InfluxDB2::Point.new(name: 'h2o')
                       .add_tag('location', 'europe')
                       .add_field('level', 2)

hash = { name: 'h2o',
         tags: { host: 'aws', region: 'us' },
         fields: { level: 5, saturation: '99%' }, time: 123 }

write_api = client.create_write_api
write_api.write(data: ['h2o,location=west value=33i 15', point, hash])
```

### Delete data

The [DeleteApi](https://github.com/influxdata/influxdb-client-ruby/blob/master/lib/influxdb2/client/delete_api.rb) supports deletes [points](https://v2.docs.influxdata.com/v2.0/reference/glossary/#point) from an InfluxDB bucket.

```ruby
client = InfluxDB2::Client.new('http://localhost:9999', 'my-token',
                               bucket: 'my-bucket',
                               org: 'my-org',
                               precision: InfluxDB2::WritePrecision::NANOSECOND)

client.create_delete_api.delete(DateTime.rfc3339('2019-02-03T04:05:06+07:00'),
                                DateTime.rfc3339('2019-03-03T04:05:06+07:00'),
                                predicate: 'key1="value1" AND key2="value"')
```

The time range could be specified as:

1. String - `"2019-02-03T04:05:06+07:00"`
1. DateTime - `DateTime.rfc3339('2019-03-03T04:05:06+07:00')`
1. Time - `Time.utc(2015, 10, 16, 8, 20, 15)`

## Advanced Usage

### Check the server status 

Server availability can be checked using the `client.health` method. That is equivalent of the [influx ping](https://v2.docs.influxdata.com/v2.0/reference/cli/influx/ping/).

### InfluxDB 1.8 API compatibility

[InfluxDB 1.8.0 introduced forward compatibility APIs](https://docs.influxdata.com/influxdb/latest/tools/api/#influxdb-2-0-api-compatibility-endpoints) for InfluxDB 2.0. This allow you to easily move from InfluxDB 1.x to InfluxDB 2.0 Cloud or open source.

The following forward compatible APIs are available:

| API | Endpoint | Description |
|:----------|:----------|:----------|
| [query_api.rb](lib/influxdb2/client/query_api.rb) | [/api/v2/query](https://docs.influxdata.com/influxdb/latest/tools/api/#api-v2-query-http-endpoint) | Query data in InfluxDB 1.8.0+ using the InfluxDB 2.0 API and [Flux](https://docs.influxdata.com/flux/latest/) _(endpoint should be enabled by [`flux-enabled` option](https://docs.influxdata.com/influxdb/latest/administration/config/#flux-enabled-false))_  |
| [write_api.rb](lib/influxdb2/client/write_api.rb) | [/api/v2/write](https://docs.influxdata.com/influxdb/latest/tools/api/#api-v2-write-http-endpoint) | Write data to InfluxDB 1.8.0+ using the InfluxDB 2.0 API |
| [health_api.rb](lib/influxdb2/client/health_api.rb) | [/health](https://docs.influxdata.com/influxdb/latest/tools/api/#health-http-endpoint) | Check the health of your InfluxDB instance |    

For detail info see [InfluxDB 1.8 example](examples/influxdb_18_example.rb).

## Local tests

```
brew install wget # on a mac, if not yet installed!
bin/influxdb-restart.sh
rake test
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/influxdata/influxdb-client-ruby.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
