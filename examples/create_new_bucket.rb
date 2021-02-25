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
