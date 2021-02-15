# The MIT License
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#

require 'influxdb2/apis/api'
require 'influxdb2/apis/version'

# Common files
require 'influxdb2/apis/generated/api_client'
require 'influxdb2/apis/generated/api_error'
require 'influxdb2/apis/generated/configuration'

# Models
require 'influxdb2/apis/generated/models/authorization'
require 'influxdb2/apis/generated/models/authorization_all_of'
require 'influxdb2/apis/generated/models/authorization_all_of_links'
require 'influxdb2/apis/generated/models/authorization_update_request'
require 'influxdb2/apis/generated/models/authorizations'
require 'influxdb2/apis/generated/models/bucket'
require 'influxdb2/apis/generated/models/bucket_links'
require 'influxdb2/apis/generated/models/buckets'
require 'influxdb2/apis/generated/models/label'
require 'influxdb2/apis/generated/models/label_create_request'
require 'influxdb2/apis/generated/models/label_mapping'
require 'influxdb2/apis/generated/models/label_response'
require 'influxdb2/apis/generated/models/label_update'
require 'influxdb2/apis/generated/models/labels_response'
require 'influxdb2/apis/generated/models/links'
require 'influxdb2/apis/generated/models/organization'
require 'influxdb2/apis/generated/models/organization_links'
require 'influxdb2/apis/generated/models/organizations'
require 'influxdb2/apis/generated/models/permission'
require 'influxdb2/apis/generated/models/post_bucket_request'
require 'influxdb2/apis/generated/models/resource'
require 'influxdb2/apis/generated/models/resource_member'
require 'influxdb2/apis/generated/models/resource_member_all_of'
require 'influxdb2/apis/generated/models/resource_members'
require 'influxdb2/apis/generated/models/resource_owner'
require 'influxdb2/apis/generated/models/resource_owner_all_of'
require 'influxdb2/apis/generated/models/resource_owners'
require 'influxdb2/apis/generated/models/retention_rule'
require 'influxdb2/apis/generated/models/user'
require 'influxdb2/apis/generated/models/user_links'
require 'influxdb2/apis/generated/models/users'
require 'influxdb2/apis/generated/models/users_links'

# APIs
require 'influxdb2/apis/generated/api/authorizations_api'
require 'influxdb2/apis/generated/api/buckets_api'
require 'influxdb2/apis/generated/api/labels_api'
require 'influxdb2/apis/generated/api/organizations_api'
require 'influxdb2/apis/generated/api/users_api'
