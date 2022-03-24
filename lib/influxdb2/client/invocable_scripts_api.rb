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

require_relative 'models/script'

module InfluxDB2
  # Use API invokable scripts to create custom InfluxDB API endpoints that query, process, and shape data.
  #
  # API invokable scripts let you assign scripts to API endpoints and then execute them as standard REST operations
  # in InfluxDB Cloud.
  class InvocableScriptsApi < DefaultApi
    # @param [Hash] options The options to be used by the client.
    def initialize(options:)
      super(options: options)
    end

    # Create a script.
    #
    # @param script_create_request [ScriptCreateRequest] The script to create.
    # @return [Script] The created script.
    def create_script(script_create_request)
      uri = _parse_uri('/api/v2/scripts')

      response = _request_json(script_create_request.to_body.to_json, uri, headers: { 'Accept' => 'application/json' })
      body = response.body

      data = JSON.parse("[#{body}]", symbolize_names: true)[0]
      Script.build_from_hash(data)
    end

    # Update a script.
    #
    # @param script_id [String] The ID of the script to update. (required)
    # @param update_request [ScriptUpdateRequest] Script updates to apply (required)
    # @return [Script] The updated script.
    def update_script(script_id, update_request)
      uri = _parse_uri('/api/v2/scripts/' + URI.encode_www_form_component(script_id))

      response = _request_json(update_request.to_body.to_json, uri, headers: { 'Accept' => 'application/json' },
                                                                    method: Net::HTTP::Patch)
      body = response.body

      data = JSON.parse("[#{body}]", symbolize_names: true)[0]
      Script.build_from_hash(data)
    end

    # Delete a script.
    #
    # @param script_id [String] The ID of the script to delete. (required)
    def delete_script(script_id)
      uri = _parse_uri('/api/v2/scripts/' + URI.encode_www_form_component(script_id))

      _request_json('', uri, headers: { 'Accept' => 'application/json' },
                             method: Net::HTTP::Delete)
    end
  end
end
