require 'influxdb-client'

url = 'http://localhost:8086'
token = 'my-token'
bucket = 'my-bucket'
org = 'my-org'

client = InfluxDB2::Client.new(url,
                               token,
                               bucket: bucket,
                               org: org,
                               precision: InfluxDB2::WritePrecision::NANOSECOND,
                               use_ssl: false)

# Prepare Data
write_api = client.create_write_api
(1..5).each do |i|
  write_api.write(data: "point,table=my-table result=#{i}", bucket: bucket, org: org)
end

# Query data with pivot
query_api = client.create_query_api
query = "from(bucket: \"#{bucket}\") |> range(start: -1m) |> filter(fn: (r) => (r[\"_measurement\"] == \"point\"))
|> pivot(rowKey:[\"_time\"], columnKey: [\"_field\"], valueColumn: \"_value\")"
result = query_api.query(query: query)

# Write data to output
puts '----------------------------------------------- FluxRecord.values ----------------------------------------------'
result[0].records.each do |record|
  puts record.values
end

puts '------------------------------------------------- FluxRecord.row -----------------------------------------------'
result[0].records.each do |record|
  puts record.row.join(',')
end

client.close!
