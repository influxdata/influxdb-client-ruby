## 1.6.0 [2020-07-17]

### Bug Fixes
1. [#42](https://github.com/influxdata/influxdb-client-ruby/pull/42): Fixed serialization of `\n`, `\r` and `\t` to Line Protocol, `=` is valid sign for measurement name  
1. [#44](https://github.com/influxdata/influxdb-client-ruby/pull/44): Fixed supporting of Ruby 2.2

## 1.5.0 [2020-06-19]

### API
1. [#41](https://github.com/influxdata/influxdb-client-ruby/pull/41): Updated swagger to latest version

## 1.4.0 [2020-05-15]

### Features

1. [#38](https://github.com/influxdata/influxdb-client-ruby/pull/38): Remove trailing slash from connection URL

### Documentation

1. [#37](https://github.com/influxdata/influxdb-client-ruby/pull/37): Fix documentation: replace references to InfluxDB module by InfluxDB2. Allow `require 'influxdb-client'`

## 1.3.0 [2020-04-17]

### Features

1. [#32](https://github.com/influxdata/influxdb-client-ruby/pull/32): Checks the health of a running InfluxDB instance by querying the /health

### Documentation

1. [#35](https://github.com/influxdata/influxdb-client-ruby/pull/35): Clarify how to use a client with InfluxDB 1.8

## 1.2.0 [2020-03-13]

### Features
1. [#23](https://github.com/influxdata/influxdb-client-ruby/issues/23): Added DeleteApi to delete time series data from InfluxDB.
1. [#24](https://github.com/influxdata/influxdb-client-ruby/issues/24): Added jitter_interval and retry_interval to WriteApi
1. [#26](https://github.com/influxdata/influxdb-client-ruby/issues/26): Set User-Agent to influxdb-client-ruby/VERSION for all requests

### Security
1. [#29](https://github.com/influxdata/influxdb-client-ruby/pull/29): Upgrade rake to version 12.3.3 - [CVE-2020-8130](https://github.com/advisories/GHSA-jppv-gw3r-w3q8)

### Bug Fixes
1. [#22](https://github.com/influxdata/influxdb-client-ruby/pull/22): Fixed batch write
1. [#28](https://github.com/influxdata/influxdb-client-ruby/pull/28): Correctly parse CSV where multiple results include multiple tables
1. [#30](https://github.com/influxdata/influxdb-client-ruby/pull/30): Send Content-Type headers

## 1.1.0 [2020-02-14]

### Features
1. [#14](https://github.com/influxdata/influxdb-client-ruby/issues/14): Added QueryApi
2. [#17](https://github.com/influxdata/influxdb-client-ruby/issues/17): Added possibility to stream query result
3. [#19](https://github.com/influxdata/influxdb-client-ruby/issues/19): Added WriteOptions and possibility to batch write
 
## 1.0.0.beta [2020-01-17]

### Features
1. [#4](https://github.com/influxdata/influxdb-client-ruby/pull/4): Added WriteApi that will be used for Fluentd plugin
 
