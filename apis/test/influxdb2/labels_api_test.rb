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

class LabelsApiTest < BaseApiTests
  def setup
    super
    @client.create_labels_api.get_labels.labels.each do |label|
      next unless label.name.end_with?('_TEST')

      @client.create_labels_api.delete_labels_id(label.id)
    end
  end

  def test_create_label
    name = generate_name('label')
    user = InfluxDB2::API::LabelCreateRequest.new(name: name, org_id: @my_org.id)

    result = @client.create_labels_api.post_labels(user)

    refute_nil result.links
    refute_nil result.label.id
    assert_equal name, result.label.name
    assert_equal @my_org.id, result.label.org_id
  end
end
