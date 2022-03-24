$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'influxdb-client'

# warning: Parameterized Queries are supported only in InfluxDB Cloud, currently there is no support in InfluxDB OSS.

url = 'https://us-west-2-1.aws.cloud2.influxdata.com'
token = '...'
bucket = '...'
org = '...'

client = InfluxDB2::Client.new(url, token, bucket: bucket, org: org)



client.close!
