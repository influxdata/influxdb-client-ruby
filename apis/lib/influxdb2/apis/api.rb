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
module InfluxDB2
  module API
    # The client is the entry point to management HTTP API defined
    # in https://github.com/influxdata/influxdb/blob/master/http/swagger.yml.
    class Client
      attr_accessor :api_client

      # Initialize client that providing a support for managements APIs.
      #
      # @example Instantiate a client.
      #   client = InfluxDBClient::Client.new(url: 'https://localhost:8086', token: 'my-token')
      #   api = InfluxDB2::API::Client.new(client)
      #
      # @param [InfluxDB2::Client] :client The main InfluxDB client
      def initialize(client)
        configuration = Configuration.new

        uri = URI.parse(client.options[:url])
        # base URL
        configuration.scheme = uri.scheme
        configuration.host = uri.to_s
        # SSL
        configuration.verify_ssl = client.options[:use_ssl].nil? ? true : client.options[:use_ssl]
        # Token
        configuration.api_key_prefix['api_key'] = 'Token'
        configuration.api_key['api_key'] = client.options[:token]

        @api_client = ApiClient.new(configuration)
        # User Agent
        @api_client.user_agent = "influxdb-client-ruby/#{InfluxDB2::VERSION}"
      end

      # Create a new instance of AuthorizationsApi.
      #
      # @return [InfluxDB2::API::AuthorizationsApi] New instance of OrganizationsApi.
      def create_authorization_api
        InfluxDB2::AuthorizationsApi.new(@api_client)
      end

      # Create a new instance of BucketsApi.
      #
      # @return [InfluxDB2::API::BucketsApi] New instance of BucketsApi.
      def create_bucket_api
        InfluxDB2::BucketsApi.new(@api_client)
      end

      # Create a new instance of OrganizationsApi.
      #
      # @return [InfluxDB2::API::OrganizationsApi] New instance of OrganizationsApi.
      def create_organization_api
        InfluxDB2::OrganizationsApi.new(@api_client)
      end

      # Create a new instance of UsersApi.
      #
      # @return [InfluxDB2::API::UsersApi] New instance of UsersApi.
      def create_user_api
        InfluxDB2::UsersApi.new(@api_client)
      end
    end
  end
end
