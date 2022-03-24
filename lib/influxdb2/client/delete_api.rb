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

require_relative 'models/delete_predicate_request'

module InfluxDB2
  # Delete time series data from InfluxDB
  #
  class DeleteApi < DefaultApi
    # @param [Hash] options The options to be used by the client.
    def initialize(options:)
      super(options: options)
    end

    # Delete time series data from InfluxDB.
    #
    # @example
    # delete('2019-02-03T04:05:06+07:00', '2019-04-03T04:05:06+07:00',
    #        predicate: 'key1="value1" AND key2="value"', bucket: 'my-bucket', org: 'my-org')
    #
    # @example
    # delete(DateTime.rfc3339('2019-02-03T04:05:06+07:00'), DateTime.rfc3339('2019-03-03T04:05:06+07:00'),
    #        predicate: 'key1="value1" AND key2="value"', bucket: 'my-bucket', org: 'my-org')
    #
    # @param [Object] start Start time of interval to delete data.
    #   The start could be represent by [Time], [DateTime] or [String] formatted as RFC3339.
    # @param [Object] stop Stop time of interval to delete data
    #   The stop could be represent by [Time], [DateTime] or [String] formatted as RFC3339.
    # @param [String] predicate InfluxQL-like predicate Stop time of interval to delete data
    # @param [String] bucket specifies the bucket to remove data from
    # @param [String] org specifies the organization to remove data from
    def delete(start, stop, predicate: nil, bucket: nil, org: nil)
      delete_request = InfluxDB2::DeletePredicateRequest.new(start: _to_rfc3339(start), stop: _to_rfc3339(stop),
                                                             predicate: predicate)

      _delete(delete_request, bucket: bucket, org: org)
    end

    private

    def _delete(delete_request, bucket: nil, org: nil)
      bucket_param = bucket || @options[:bucket]
      org_param = org || @options[:org]
      _check('bucket', bucket_param)
      _check('org', org_param)

      uri = _parse_uri('/api/v2/delete')
      uri.query = URI.encode_www_form(org: org_param, bucket: bucket_param)

      _request_json(delete_request.to_body.to_json, uri)
    end

    def _to_rfc3339(time)
      if time.is_a?(String)
        time
      elsif time.is_a?(Time)
        _to_rfc3339(time.to_datetime)
      elsif time.is_a?(DateTime)
        _to_rfc3339(time.rfc3339)
      end
    end
  end
end
