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

require 'test_helper'

class AuthorizationsApiTest < BaseApiTests
  def setup
    super
    @client.create_authorizations_api.get_authorizations.authorizations.each do |auth|
      next unless auth.description.end_with?('_TEST')

      @client.create_authorizations_api.delete_authorizations_id(auth.id)
    end
  end

  def test_create_authorization
    description = generate_name('organization')

    resource = InfluxDB2::API::Resource.new(type: 'users', org_id: my_org.id)
    permission = InfluxDB2::API::Permission.new(action: 'read', resource: resource)
    authorization = InfluxDB2::API::Authorization.new(description: description,
                                                      org_id: @my_org.id,
                                                      permissions: [permission])

    result = @client.create_authorizations_api.post_authorizations(authorization)

    refute_nil result.id
    refute_nil result.links
    assert_equal description, result.description
    assert_equal @my_org.id, result.org_id
    assert_equal 'read', result.permissions[0].action
    assert_equal 'users', result.permissions[0].resource.type
  end
end
