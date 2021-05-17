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

class OrganizationsApiTest < BaseApiTests
  def setup
    super
    @client.create_organizations_api.get_orgs.orgs.each do |org|
      next unless org.name.end_with?('_TEST')

      @client.create_organizations_api.delete_orgs_id(org.id)
    end
  end

  def test_create_org
    name = generate_name('organization')
    organization = InfluxDB2::API::PostOrganizationRequest.new(name: name)

    result = @client.create_organizations_api.post_orgs(organization)

    refute_nil result.id
    refute_nil result.links
    assert_equal name, result.name
  end

  def test_get_members
    organization = InfluxDB2::API::PostOrganizationRequest.new(name: generate_name('organization'))
    result = @client.create_organizations_api.post_orgs(organization)

    members = @client.create_organizations_api.get_orgs_id_members(result.id)
    assert_equal 0, members.users.length
  end

  def test_get_owners
    organization = InfluxDB2::API::PostOrganizationRequest.new(name: generate_name('organization'))
    result = @client.create_organizations_api.post_orgs(organization)

    owners = @client.create_organizations_api.get_orgs_id_owners(result.id)
    assert_equal 1, owners.users.length
    assert_equal 'my-user', owners.users[0].name
  end
end
