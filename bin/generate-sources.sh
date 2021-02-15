#!/usr/bin/env bash

SCRIPT_PATH="$( cd "$(dirname "$0")" || exit ; pwd -P )"

rm -rf "${SCRIPT_PATH}"/generated

# Generate client
cd "${SCRIPT_PATH}"/ || exit
mvn org.openapitools:openapi-generator-maven-plugin:generate

#### sync generated swift files to src
mkdir "${SCRIPT_PATH}"/../lib/influxdb2/client/models/ || true
mkdir "${SCRIPT_PATH}"/../apis/lib/influxdb2/apis/generated || true
mkdir "${SCRIPT_PATH}"/../apis/lib/influxdb2/apis/generated/models/ || true
mkdir "${SCRIPT_PATH}"/../apis/lib/influxdb2/apis/generated/api/ || true

## delete old sources
rm -f "${SCRIPT_PATH}"/../lib/influxdb2/client/models/*.rb
rm -f "${SCRIPT_PATH}"/../apis/lib/influxdb2/apis/generated/*.rb
rm -f "${SCRIPT_PATH}"/../apis/lib/influxdb2/apis/generated/models/*.rb
rm -f "${SCRIPT_PATH}"/../apis/lib/influxdb2/apis/generated/api/*.rb

## copy apis
cp -r "${SCRIPT_PATH}"/generated/lib/influx_db2/api/authorizations_api.rb "${SCRIPT_PATH}"/../apis/lib/influxdb2/apis/generated/api/
cp -r "${SCRIPT_PATH}"/generated/lib/influx_db2/api/buckets_api.rb "${SCRIPT_PATH}"/../apis/lib/influxdb2/apis/generated/api/
cp -r "${SCRIPT_PATH}"/generated/lib/influx_db2/api/labels_api.rb "${SCRIPT_PATH}"/../apis/lib/influxdb2/apis/generated/api/
cp -r "${SCRIPT_PATH}"/generated/lib/influx_db2/api/organizations_api.rb "${SCRIPT_PATH}"/../apis/lib/influxdb2/apis/generated/api/
cp -r "${SCRIPT_PATH}"/generated/lib/influx_db2/api/users_api.rb "${SCRIPT_PATH}"/../apis/lib/influxdb2/apis/generated/api/

## copy models
cp -r "${SCRIPT_PATH}"/generated/lib/influx_db2/models/health_check.rb "${SCRIPT_PATH}"/../lib/influxdb2/client/models/
cp -r "${SCRIPT_PATH}"/generated/lib/influx_db2/models/dialect.rb "${SCRIPT_PATH}"/../lib/influxdb2/client/models/
cp -r "${SCRIPT_PATH}"/generated/lib/influx_db2/models/query.rb "${SCRIPT_PATH}"/../lib/influxdb2/client/models/
cp -r "${SCRIPT_PATH}"/generated/lib/influx_db2/models/delete_predicate_request.rb "${SCRIPT_PATH}"/../lib/influxdb2/client/models/
cp -r "${SCRIPT_PATH}"/generated/lib/influx_db2/models/bucket.rb "${SCRIPT_PATH}"/../apis/lib/influxdb2/apis/generated/models/
cp -r "${SCRIPT_PATH}"/generated/lib/influx_db2/models/bucket_links.rb "${SCRIPT_PATH}"/../apis/lib/influxdb2/apis/generated/models/
cp -r "${SCRIPT_PATH}"/generated/lib/influx_db2/models/buckets.rb "${SCRIPT_PATH}"/../apis/lib/influxdb2/apis/generated/models/
cp -r "${SCRIPT_PATH}"/generated/lib/influx_db2/models/retention_rule.rb "${SCRIPT_PATH}"/../apis/lib/influxdb2/apis/generated/models/
cp -r "${SCRIPT_PATH}"/generated/lib/influx_db2/models/post_bucket_request.rb "${SCRIPT_PATH}"/../apis/lib/influxdb2/apis/generated/models/
cp -r "${SCRIPT_PATH}"/generated/lib/influx_db2/models/organization.rb "${SCRIPT_PATH}"/../apis/lib/influxdb2/apis/generated/models/
cp -r "${SCRIPT_PATH}"/generated/lib/influx_db2/models/organization_links.rb "${SCRIPT_PATH}"/../apis/lib/influxdb2/apis/generated/models/
cp -r "${SCRIPT_PATH}"/generated/lib/influx_db2/models/organizations.rb "${SCRIPT_PATH}"/../apis/lib/influxdb2/apis/generated/models/
cp -r "${SCRIPT_PATH}"/generated/lib/influx_db2/models/links.rb "${SCRIPT_PATH}"/../apis/lib/influxdb2/apis/generated/models/
cp -r "${SCRIPT_PATH}"/generated/lib/influx_db2/models/authorization.rb "${SCRIPT_PATH}"/../apis/lib/influxdb2/apis/generated/models/
cp -r "${SCRIPT_PATH}"/generated/lib/influx_db2/models/authorization_update_request.rb "${SCRIPT_PATH}"/../apis/lib/influxdb2/apis/generated/models/
cp -r "${SCRIPT_PATH}"/generated/lib/influx_db2/models/authorizations.rb "${SCRIPT_PATH}"/../apis/lib/influxdb2/apis/generated/models/
cp -r "${SCRIPT_PATH}"/generated/lib/influx_db2/models/authorization_all_of.rb "${SCRIPT_PATH}"/../apis/lib/influxdb2/apis/generated/models/
cp -r "${SCRIPT_PATH}"/generated/lib/influx_db2/models/authorization_all_of_links.rb "${SCRIPT_PATH}"/../apis/lib/influxdb2/apis/generated/models/
cp -r "${SCRIPT_PATH}"/generated/lib/influx_db2/models/permission.rb "${SCRIPT_PATH}"/../apis/lib/influxdb2/apis/generated/models/
cp -r "${SCRIPT_PATH}"/generated/lib/influx_db2/models/resource.rb "${SCRIPT_PATH}"/../apis/lib/influxdb2/apis/generated/models/
cp -r "${SCRIPT_PATH}"/generated/lib/influx_db2/models/resource_member.rb "${SCRIPT_PATH}"/../apis/lib/influxdb2/apis/generated/models/
cp -r "${SCRIPT_PATH}"/generated/lib/influx_db2/models/resource_member_all_of.rb "${SCRIPT_PATH}"/../apis/lib/influxdb2/apis/generated/models/
cp -r "${SCRIPT_PATH}"/generated/lib/influx_db2/models/resource_members.rb "${SCRIPT_PATH}"/../apis/lib/influxdb2/apis/generated/models/
cp -r "${SCRIPT_PATH}"/generated/lib/influx_db2/models/resource_owner.rb "${SCRIPT_PATH}"/../apis/lib/influxdb2/apis/generated/models/
cp -r "${SCRIPT_PATH}"/generated/lib/influx_db2/models/resource_owner_all_of.rb "${SCRIPT_PATH}"/../apis/lib/influxdb2/apis/generated/models/
cp -r "${SCRIPT_PATH}"/generated/lib/influx_db2/models/resource_owners.rb "${SCRIPT_PATH}"/../apis/lib/influxdb2/apis/generated/models/
cp -r "${SCRIPT_PATH}"/generated/lib/influx_db2/models/user.rb "${SCRIPT_PATH}"/../apis/lib/influxdb2/apis/generated/models/
cp -r "${SCRIPT_PATH}"/generated/lib/influx_db2/models/user_links.rb "${SCRIPT_PATH}"/../apis/lib/influxdb2/apis/generated/models/
cp -r "${SCRIPT_PATH}"/generated/lib/influx_db2/models/users.rb "${SCRIPT_PATH}"/../apis/lib/influxdb2/apis/generated/models/
cp -r "${SCRIPT_PATH}"/generated/lib/influx_db2/models/users_links.rb "${SCRIPT_PATH}"/../apis/lib/influxdb2/apis/generated/models/
cp -r "${SCRIPT_PATH}"/generated/lib/influx_db2/models/label.rb "${SCRIPT_PATH}"/../apis/lib/influxdb2/apis/generated/models/
cp -r "${SCRIPT_PATH}"/generated/lib/influx_db2/models/label_create_request.rb "${SCRIPT_PATH}"/../apis/lib/influxdb2/apis/generated/models/
cp -r "${SCRIPT_PATH}"/generated/lib/influx_db2/models/label_mapping.rb "${SCRIPT_PATH}"/../apis/lib/influxdb2/apis/generated/models/
cp -r "${SCRIPT_PATH}"/generated/lib/influx_db2/models/label_response.rb "${SCRIPT_PATH}"/../apis/lib/influxdb2/apis/generated/models/
cp -r "${SCRIPT_PATH}"/generated/lib/influx_db2/models/label_update.rb "${SCRIPT_PATH}"/../apis/lib/influxdb2/apis/generated/models/
cp -r "${SCRIPT_PATH}"/generated/lib/influx_db2/models/labels_response.rb "${SCRIPT_PATH}"/../apis/lib/influxdb2/apis/generated/models/

# copy supporting files
cp -r "${SCRIPT_PATH}"/generated/lib/influx_db2/api_client.rb "${SCRIPT_PATH}"/../apis/lib/influxdb2/apis/generated/
cp -r "${SCRIPT_PATH}"/generated/lib/influx_db2/api_error.rb "${SCRIPT_PATH}"/../apis/lib/influxdb2/apis/generated/
cp -r "${SCRIPT_PATH}"/generated/lib/influx_db2/configuration.rb "${SCRIPT_PATH}"/../apis/lib/influxdb2/apis/generated/

# post process sources
sed -i '' 's/::API//' "${SCRIPT_PATH}"/../lib/influxdb2/client/models/health_check.rb
sed -i '' 's/::API//' "${SCRIPT_PATH}"/../lib/influxdb2/client/models/dialect.rb
sed -i '' 's/::API//' "${SCRIPT_PATH}"/../lib/influxdb2/client/models/query.rb
sed -i '' 's/::API//' "${SCRIPT_PATH}"/../lib/influxdb2/client/models/delete_predicate_request.rb

#rm -rf "${SCRIPT_PATH}"/generated
