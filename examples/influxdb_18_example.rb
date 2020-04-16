$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'influxdb2/client'

username = 'username'
password = 'password'

database = 'telegraf'
retention_policy = 'autogen'

bucket = "#{database}/#{retention_policy}"

client = InfluxDB2::Client.new('http://localhost:8086',
                               "#{username}:#{password}",
                               bucket: bucket,
                               org: '-',
                               use_ssl: false,
                               precision: InfluxDB2::WritePrecision::NANOSECOND)

puts '*** Write Points ***'

write_api = client.create_write_api
point = InfluxDB2::Point.new(name: 'mem')
                        .add_tag('host', 'host1')
                        .add_field('used_percent', 21.43234543)
puts point.to_line_protocol
write_api.write(data: point)

puts '*** Query Points ***'

query_api = client.create_query_api
query = "from(bucket: \"#{bucket}\") |> range(start: -1h)"
result = query_api.query(query: query)
result[0].records.each { |record| puts "#{record.time} #{record.measurement}: #{record.field} #{record.value}" }

client.close!
