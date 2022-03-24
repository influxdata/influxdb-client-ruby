$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'influxdb-client'

# warning: Invocable Scripts are supported only in InfluxDB Cloud, currently there is no support in InfluxDB OSS.

url = 'https://us-west-2-1.aws.cloud2.influxdata.com'
token = '...'
bucket = '...'
org = '...'

client = InfluxDB2::Client.new(url, token, bucket: bucket, org: org, precision: InfluxDB2::WritePrecision::NANOSECOND)

unique_id = Time.now.utc.to_i.to_s
#
# Prepare data
#
point1 = InfluxDB2::Point.new(name: 'my_measurement')
                         .add_tag('location', 'Prague')
                         .add_field('temperature', 25.3)
point2 = InfluxDB2::Point.new(name: 'my_measurement')
                         .add_tag('location', 'New York')
                         .add_field('temperature', 24.3)
client.create_write_api.write(data: [point1, point2])

scripts_api = client.create_invocable_scripts_api

#
# Create Invocable Script
#
puts "------- Create -------\n"
script_query = 'from(bucket: params.bucket_name) |> range(start: -30d) |> limit(n:2)'
create_request = InfluxDB2::ScriptCreateRequest.new(name: "my_script_#{unique_id}",
                                                    description: 'my first try',
                                                    language: InfluxDB2::ScriptLanguage::FLUX,
                                                    script: script_query)

created_script = scripts_api.create_script(create_request)
puts created_script.inspect

#
# Update Invocable Script
#
puts "------- Update -------\n"
update_request = InfluxDB2::ScriptCreateRequest.new(description: 'my updated description')
created_script = scripts_api.update_script(created_script.id, update_request)
puts created_script.inspect

client.close!
