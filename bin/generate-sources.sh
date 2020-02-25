#!/usr/bin/env bash

#!/usr/bin/env bash

SCRIPT_PATH="$( cd "$(dirname "$0")" || exit ; pwd -P )"

# delete old sources
rm "${SCRIPT_PATH}"/../lib/influxdb2/client/models/*

# Generate client
cd "${SCRIPT_PATH}"/ || exit
mvn org.openapitools:openapi-generator-maven-plugin:generate

# Move sources
mkdir -p "${SCRIPT_PATH}"/../lib/influxdb2/client/models
mv "${SCRIPT_PATH}"/../lib/influx_db2/models/* "${SCRIPT_PATH}"/../lib/influxdb2/client/models

cd "${SCRIPT_PATH}"/../lib/influxdb2/client/models || exit
rm -r $(ls | grep -v "\<dialect.rb\>\|\<query.rb\>\|\<delete_predicate_request.rb\>")

# Clean
rmdir "${SCRIPT_PATH}"/../lib/influx_db2/models
rmdir "${SCRIPT_PATH}"/../lib/influx_db2/
