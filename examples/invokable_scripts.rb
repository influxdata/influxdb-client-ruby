$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'influxdb-client'

# warning: Invokable Scripts are supported only in InfluxDB Cloud, currently there is no support in InfluxDB OSS.

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

scripts_api = client.create_invokable_scripts_api

#
# Create Invokable Script
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
# Update Invokable Script
#
puts "------- Update -------\n"
update_request = InfluxDB2::ScriptUpdateRequest.new(description: 'my updated description')
created_script = scripts_api.update_script(created_script.id, update_request)
puts created_script.inspect

#
# Invoke a script
#

# FluxTables
puts "\n------- Invoke to FluxTables -------\n"
tables = scripts_api.invoke_script(created_script.id, params: { 'bucket_name' => bucket })
tables.each do |_, table|
  table.records.each do |record|
    puts "#{record.time} #{record.values['location']}: #{record.field} #{record.value}"
  end
end

# Stream of FluxRecords
puts "\n------- Invoke to Stream of FluxRecords -------\n"
records = scripts_api.invoke_script_stream(created_script.id, params: { 'bucket_name' => bucket })
records.each do |record|
  puts "#{record.time} #{record.values['location']}: #{record.field} #{record.value}"
end

# RAW
puts "\n------- Invoke to Raw-------\n"
raw = scripts_api.invoke_script_raw(created_script.id, params: { 'bucket_name' => bucket })
puts "RAW output:\n #{raw}"

#
# List scripts
#
puts "\n------- List -------\n"
scripts = scripts_api.find_scripts
scripts.each do |script|
  puts " ---\n ID: #{script.id}\n Name: #{script.name}\n Description: #{script.description}"
end
puts '---'

#
# Delete previously created Script
#
puts "------- Delete -------\n"
scripts_api.delete_script(created_script.id)
puts " Successfully deleted script: '#{created_script.name}'"

client.close!
