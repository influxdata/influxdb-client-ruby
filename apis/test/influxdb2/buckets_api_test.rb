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
# require_relative 'base_api_test'

class BucketsApiTest < BaseApiTests
  attr_reader :client
  attr_reader :main_client

  def setup
    super
    buckets = @client.create_bucket_api.get_buckets
    buckets.buckets.each do |bucket|
      next unless bucket.name.end_with?('_TEST')

      @client.create_bucket_api.delete_buckets_id(bucket.id)
    end
  end

  def test_create_bucket
    name = generate_name('bucket')
    request = InfluxDB2::API::PostBucketRequest.new(org_id: @my_org.id, name: name)

    result = @client.create_bucket_api.post_buckets(request)

    refute_nil result.id
    refute_nil result.links
    assert_equal name, result.name
    assert_equal @my_org.id, result.org_id
    assert_equal 'user', result.type
  end
end
