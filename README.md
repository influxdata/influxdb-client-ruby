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

- [Features](#features)
- [Installation](#installation)
    - [Install the Gem](#install-the-gem)
- [Usage](#usage)
    - [Creating a client](#creating-a-client)
    - [Writing data](#writing-data)
    - [Querying data](#queries)
    - [Delete data](#delete-data)
    - [Management API](#management-api)
- [Advanced Usage](#advanced-usage)
    - [Default Tags](#default-tags)
    - [Proxy configuration](#proxy-configuration)
- [Contributing](#contributing)
- [License](#license)

## Documentation

This section contains links to the client library documentation.

* [Product documentation](https://docs.influxdata.com/influxdb/v2.0/api-guide/client-libraries/), [Getting Started](#installation)
* [Examples](examples)
* [API Reference](https://influxdata.github.io/influxdb-client-ruby/InfluxDB2.html)
* [Changelog](CHANGELOG.md)

## Features

InfluxDB 2.0 client consists of two packages

- `influxdb-client`
    - Querying data using the Flux language
    - Writing data
        - batched in chunks on background
        - automatic retries on write failures
- `influxdb-client-apis`
    - provides all other InfluxDB 2.0 APIs for managing
        - buckets
        - labels
        - authorizations
        - ...
    - built on top of `influxdb-client`

## Installation

The InfluxDB 2 client is bundled as a gem and is hosted on [Rubygems](https://rubygems.org/gems/influxdb-client).

### Install the Gem

The client can be installed manually or with bundler.

To install the client gem manually:

```
gem install influxdb-client -v 2.1.0
```

For management API:

```
gem install influxdb-client-apis -v 2.1.0
```

## Usage

### Creating a client

Use **InfluxDB::Client** to create a client connected to a running InfluxDB 2 instance.

```ruby
client = InfluxDB2::Client.new('https://localhost:8086', 'my-token')
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
| redirect_forward_authorization | Pass Authorization header to different domain during HTTP redirect. | bool | false |
| use_ssl | Turn on/off SSL for HTTP communication | bool | true |
| verify_mode | Sets the flags for the certification verification at beginning of SSL/TLS session. | `OpenSSL::SSL::VERIFY_NONE` or `OpenSSL::SSL::VERIFY_PEER` | none |

```ruby
client = InfluxDB2::Client.new('https://localhost:8086', 'my-token',
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
client = InfluxDB2::Client.new('https://localhost:8086', 'my-token',
                              bucket: 'my-bucket',
                              org: 'my-org')

query_api = client.create_query_api
result = query_api.query_raw(query: 'from(bucket:"' + bucket + '") |> range(start: 1970-01-01T00:00:00.000000001Z) |> last()')
```
#### Synchronous query
Synchronously executes the Flux query and return result as a Array of [FluxTables](https://github.com/influxdata/influxdb-client-ruby/blob/master/lib/influxdb2/client/flux_table.rb)
```ruby
client = InfluxDB2::Client.new('https://localhost:8086', 'my-token',
                              bucket: 'my-bucket',
                              org: 'my-org')

query_api = client.create_query_api
result = query_api.query(query: 'from(bucket:"' + bucket + '") |> range(start: 1970-01-01T00:00:00.000000001Z) |> last()')
```

#### Query stream
Synchronously executes the Flux query and return stream of [FluxRecord](https://github.com/influxdata/influxdb-client-ruby/blob/master/lib/influxdb2/client/flux_table.rb)
```ruby
client = InfluxDB2::Client.new('https://localhost:8086', 'my-token',
                              bucket: 'my-bucket',
                              org: 'my-org')

query_api = client.create_query_api

query = 'from(bucket: "my-bucket") |> range(start: -10m, stop: now()) ' \
      "|> filter(fn: (r) => r._measurement == \"#{measurement}\")"

query_api.query_stream(query: query).each do |record|
  puts record.to_s
end
```

#### Parameterized queries
InfluxDB Cloud supports [Parameterized Queries](https://docs.influxdata.com/influxdb/cloud/query-data/parameterized-queries/)
that let you dynamically change values in a query using the InfluxDB API. Parameterized queries make Flux queries more
reusable and can also be used to help prevent injection attacks.

InfluxDB Cloud inserts the params object into the Flux query as a Flux record named `params`. Use dot or bracket
notation to access parameters in the `params` record in your Flux query. Parameterized Flux queries support only `int`
, `float`, and `string` data types. To convert the supported data types into
other [Flux basic data types, use Flux type conversion functions](https://docs.influxdata.com/influxdb/cloud/query-data/parameterized-queries/#supported-parameter-data-types).

Parameterized query example:
> :warning: Parameterized Queries are supported only in InfluxDB Cloud, currently there is no support in InfluxDB OSS.

```ruby
client = InfluxDB2::Client.new('https://localhost:8086', 'my-token',
                              bucket: 'my-bucket',
                              org: 'my-org')

query = 'from(bucket: params.bucketParam) |> range(start: duration(v: params.startParam))'
params = { 'bucketParam' => 'my-bucket', 'startParam' => '-1h' }

query_api = client.create_query_api
result = query_api.query(query: query, params: params)

result[0].records.each { |record| puts "#{record.time} #{record.measurement}: #{record.field} #{record.value}" }
```

### Writing data
The [WriteApi](https://github.com/influxdata/influxdb-client-ruby/blob/master/lib/influxdb2/client/write_api.rb) supports synchronous and batching writes into InfluxDB 2.0. In default api uses synchronous write. To enable batching you can use WriteOption.

```ruby
client = InfluxDB2::Client.new('https://localhost:8086', 'my-token',
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
| batchSize | the number of data point to collect in batch | 1_000 |
| flush_interval | the number of milliseconds before the batch is written | 1_000 |
| retry_interval | the number of milliseconds to retry unsuccessful write. The retry interval is used when the InfluxDB server does not specify "Retry-After" header. | 5_000 |
| jitter_interval | the number of milliseconds to increase the batch flush interval by a random amount | 0 |
| max_retries | the number of max retries when write fails | 5 |
| max_retry_delay | maximum delay when retrying write in milliseconds | 125_000 |
| max_retry_time | maximum total retry timeout in milliseconds | 180_000 |
| exponential_base | the base for the exponential retry delay, the next delay is computed using random exponential backoff as a random value within the interval  ``retry_interval * exponential_base^(attempts-1)`` and ``retry_interval * exponential_base^(attempts)``. Example for ``retry_interval=5000, exponential_base=2, max_retry_delay=125000, total=5`` Retry delays are random distributed values within the ranges of ``[5000-10000, 10000-20000, 20000-40000, 40000-80000, 80000-125000]`` | 2 |
| batch_abort_on_exception | the batching worker will be aborted after failed retry strategy | false |
```ruby
write_options = InfluxDB2::WriteOptions.new(write_type: InfluxDB2::WriteType::BATCHING,
                                            batch_size: 10, flush_interval: 5_000, 
                                            max_retries: 3, max_retry_delay: 15_000,
                                            exponential_base: 2)
client = InfluxDB2::Client.new('http://localhost:8086',
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
client = InfluxDB2::Client.new('https://localhost:8086', 'my-token',
                              bucket: 'my-bucket',
                              org: 'my-org',
                              precision: InfluxDB2::WritePrecision::NANOSECOND)
```

Configure precision per write:
```ruby
client = InfluxDB2::Client.new('https://localhost:8086', 'my-token',
                                  bucket: 'my-bucket',
                                  org: 'my-org')

write_api = client.create_write_api
write_api.write(data: 'h2o,location=west value=33i 15', precision: InfluxDB2::WritePrecision::SECOND)
```
Allowed values for precision are:
- `InfluxDB2::WritePrecision::NANOSECOND` for nanosecond
- `InfluxDB2::WritePrecision::MICROSECOND` for microsecond
- `InfluxDB2::WritePrecision::MILLISECOND` for millisecond
- `InfluxDB2::WritePrecision::SECOND` for second

#### Configure destination

Default `bucket` and `organization` destination are configured via `InfluxDB::Client`:
```ruby
client = InfluxDB2::Client.new('https://localhost:8086', 'my-token',
                              bucket: 'my-bucket',
                              org: 'my-org')
```

but there is also possibility to override configuration per write:

```ruby
client = InfluxDB2::Client.new('https://localhost:8086', 'my-token')

write_api = client.create_write_api
write_api.write(data: 'h2o,location=west value=33i 15', bucket: 'production-data', org: 'customer-1')
```

#### Data format

The data could be written as:

1. `String` that is formatted as a InfluxDB's line protocol
1. `Hash` with keys: name, tags, fields and time
1. [Data Point](https://github.com/influxdata/influxdb-client-ruby/blob/master/lib/influxdb2/client/point.rb#L28) structure
1. `Array` of above items

```ruby
client = InfluxDB2::Client.new('https://localhost:8086', 'my-token',
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

#### Default Tags

Sometimes is useful to store same information in every measurement e.g. `hostname`, `location`, `customer`. 
The client is able to use static value, app settings or env variable as a tag value.

The expressions:
- `California Miner` - static value
- `${env.hostname}` - environment property

##### Via API

```ruby
client = InfluxDB2::Client.new('http://localhost:8086', 'my-token',
                               bucket: 'my-bucket',
                               org: 'my-org',
                               precision: InfluxDB2::WritePrecision::NANOSECOND,
                               use_ssl: false,
                               tags: { id: '132-987-655' })

point_settings = InfluxDB2::PointSettings.new(default_tags: { customer: 'California Miner' })
point_settings.add_default_tag('data_center', '${env.data_center}')

write_api = client.create_write_api(write_options: InfluxDB2::SYNCHRONOUS,
                                    point_settings: point_settings)

write_api.write(data: InfluxDB2::Point.new(name: 'h2o')
                                      .add_tag('location', 'europe')
                                      .add_field('level', 2))
```

### Delete data

The [DeleteApi](https://github.com/influxdata/influxdb-client-ruby/blob/master/lib/influxdb2/client/delete_api.rb) supports deletes [points](https://v2.docs.influxdata.com/v2.0/reference/glossary/#point) from an InfluxDB bucket.

```ruby
client = InfluxDB2::Client.new('http://localhost:8086', 'my-token',
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

### Management API

The client supports following management API:

|  | API docs |
| --- | --- |
| [**AuthorizationsApi**](https://influxdata.github.io/influxdb-client-ruby/InfluxDB2/API/AuthorizationsApi.html) | https://docs.influxdata.com/influxdb/v2.0/api/#tag/Authorizations |
| [**BucketsApi**](https://influxdata.github.io/influxdb-client-ruby/InfluxDB2/API/BucketsApi.html) | https://docs.influxdata.com/influxdb/v2.0/api/#tag/Buckets |
| [**LabelsApi**](https://influxdata.github.io/influxdb-client-ruby/InfluxDB2/API/LabelsApi.html) | https://docs.influxdata.com/influxdb/v2.0/api/#tag/Labels |
| [**OrganizationsApi**](https://influxdata.github.io/influxdb-client-ruby/InfluxDB2/API/OrganizationsApi.html) | https://docs.influxdata.com/influxdb/v2.0/api/#tag/Organizations |
| [**UsersApi**](https://influxdata.github.io/influxdb-client-ruby/InfluxDB2/API/UsersApi.html) | https://docs.influxdata.com/influxdb/v2.0/api/#tag/Users |


The following example demonstrates how to use a InfluxDB 2.0 Management API to create new bucket. For further information see docs and [examples](/examples).

```ruby
#
# This is an example how to create new bucket with permission to write.
#
# You could run example via: `cd apis && bundle exec ruby ../examples/create_new_bucket.rb`
#
$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'influxdb-client'
$LOAD_PATH.unshift File.expand_path('../apis/lib', __dir__)
require 'influxdb-client-apis'

url = 'http://localhost:8086'
bucket = 'my-bucket'
org = 'my-org'
token = 'my-token'

client = InfluxDB2::Client.new(url,
                               token,
                               bucket: bucket,
                               org: org,
                               use_ssl: false,
                               precision: InfluxDB2::WritePrecision::NANOSECOND)

api = InfluxDB2::API::Client.new(client)

# Find my organization
organization = api.create_organizations_api
                  .get_orgs
                  .orgs
                  .select { |it| it.name == 'my-org' }
                  .first

#
# Create new Bucket
#
retention_rule = InfluxDB2::API::RetentionRule.new(type: 'expire', every_seconds: 3600)
bucket_name = 'new-bucket-name'
request = InfluxDB2::API::PostBucketRequest.new(org_id: organization.id,
                                                name: bucket_name,
                                                retention_rules: [retention_rule])
bucket = api.create_buckets_api
            .post_buckets(request)

#
# Create Permission to read/write from Bucket
#
resource = InfluxDB2::API::Resource.new(type: 'buckets',
                                        id: bucket.id,
                                        org_id: organization.id)
authorization = InfluxDB2::API::Authorization.new(description: "Authorization to read/write bucket: #{bucket.name}",
                                                  org_id: organization.id,
                                                  permissions: [
                                                    InfluxDB2::API::Permission.new(action: 'read', resource: resource),
                                                    InfluxDB2::API::Permission.new(action: 'write', resource: resource)
                                                  ])
result = api.create_authorizations_api
            .post_authorizations(authorization)

print("The token: '#{result.token}' is authorized to read/write from/to bucket: '#{bucket.name}'.")

client.close!

```
- sources - [create_new_bucket.rb](/examples/create_new_bucket.rb)

## Advanced Usage

### Check the server status 

Server availability can be checked using the `client.ping` method. That is equivalent of the [influx ping](https://v2.docs.influxdata.com/v2.0/reference/cli/influx/ping/).

### Proxy configuration

You can configure the client to tunnel requests through an HTTP proxy. To configure the proxy use a `http_proxy` environment variable. 

```ruby
ENV['HTTP_PROXY'] = 'http://my-user:my-password@my-proxy:8099'
```

Client automatically follows HTTP redirects. The default redirect policy is to follow up to 10 consecutive requests.
You can configure redirect counts by the client property: `max_redirect_count`. 

Due to a security reason `Authorization` header is not forwarded when redirect leads to a different domain. 
To overcome this limitation you have to set the client property `redirect_forward_authorization` to `true`.

### InfluxDB 1.8 API compatibility

[InfluxDB 1.8.0 introduced forward compatibility APIs](https://docs.influxdata.com/influxdb/v1.8/tools/api/#influxdb-2-0-api-compatibility-endpoints) for InfluxDB 2.0. This allow you to easily move from InfluxDB 1.x to InfluxDB 2.0 Cloud or open source.

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
