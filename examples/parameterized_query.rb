$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'influxdb-client'

# warning: Parameterized Queries are supported only in InfluxDB Cloud, currently there is no support in InfluxDB OSS.

url = 'https://europe-west1-1.gcp.cloud2.influxdata.com'
token = 'my-token'
bucket = 'my-bucket'
org = 'my-org'

client = InfluxDB2::Client.new(url,
                               token,
                               bucket: bucket,
                               org: org,
                               precision: InfluxDB2::WritePrecision::NANOSECOND)

puts '*** Write Points ***'

write_api = client.create_write_api
point = InfluxDB2::Point.new(name: 'weather')
                        .add_tag('location', 'Praque')
                        .add_field('temperature', 21)
puts point.to_line_protocol
write_api.write(data: point)

puts '*** Query Points ***'

query_api = client.create_query_api
query = 'from(bucket: params.bucketParam) |> range(start: duration(v: params.startParam))'
params = { 'bucketParam' => 'my-bucket', 'startParam' => '-1h' }
result = query_api.query(query: query, params: params)
result[0].records.each { |record| puts "#{record.time} #{record.measurement}: #{record.field} #{record.value}" }

client.close!
