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
    #
    # @return [Script] The created script.
    def create_script(script_create_request)
      uri = _parse_uri('/api/v2/scripts')

      response = _request_json(script_create_request.to_body.to_json, uri, headers: { 'Accept' => 'application/json' })

      _to_object(response, Script)
    end

    # Update a script.
    #
    # @param script_id [String] The ID of the script to update. (required)
    # @param update_request [ScriptUpdateRequest] Script updates to apply (required)
    #
    # @return [Script] The updated script.
    def update_script(script_id, update_request)
      uri = _parse_uri_script(script_id)

      response = _request_json(update_request.to_body.to_json, uri, headers: { 'Accept' => 'application/json' },
                                                                    method: Net::HTTP::Patch)
      _to_object(response, Script)
    end

    # Delete a script.
    #
    # @param script_id [String] The ID of the script to delete. (required)
    def delete_script(script_id)
      uri = _parse_uri_script(script_id)

      _request_json('', uri, headers: { 'Accept' => 'application/json' },
                             method: Net::HTTP::Delete)
    end

    # List scripts.
    #
    # @param [Hash] opts the optional parameters
    # @option opts [Integer] :limit The number of scripts to return.
    # @option opts [Integer] :offset The offset for pagination.
    #
    # @return [Script]
    def find_scripts(opts = {})
      limit = !opts[:limit].nil? ? opts[:limit] : []
      offset = !opts[:offset].nil? ? opts[:offset] : []
      uri = _parse_uri('/api/v2/scripts')
      uri.query = URI.encode_www_form(limit: limit, offset: offset)

      response = _request_json('', uri, headers: { 'Accept' => 'application/json' },
                                        method: Net::HTTP::Get)

      _to_object(response, Scripts).scripts
    end

    # Invoke synchronously a script and return result as a [String].
    #
    # @param script_id [String] The ID of the script to invoke. (required)
    # @param [Enumerable] params represent key/value pairs parameters to be injected into script
    #
    # @return [String] result of query
    def invoke_script_raw(script_id, params: nil)
      _invoke_script(script_id, params: params).read_body
    end

    # Invoke synchronously a script and return result as a [FluxTable].
    #
    # @param script_id [String] The ID of the script to invoke. (required)
    # @param [Enumerable] params represent key/value pairs parameters to be injected into script
    #
    # @return [Array] list of FluxTables which are matched the query
    def invoke_script(script_id, params: nil)
      response = invoke_script_raw(script_id, params: params)
      parser = InfluxDB2::FluxCsvParser.new(response, stream: false,
                                                      response_mode: InfluxDB2::FluxResponseMode::ONLY_NAMES)

      parser.parse
      parser.tables
    end

    # Invoke synchronously a script and return result as a stream of FluxRecord.
    #
    # @param script_id [String] The ID of the script to invoke. (required)
    # @param [Enumerable] params represent key/value pairs parameters to be injected into script
    #
    # @return stream of Flux Records
    def invoke_script_stream(script_id, params: nil)
      response = _invoke_script(script_id, params: params)

      InfluxDB2::FluxCsvParser.new(response, stream: true, response_mode: InfluxDB2::FluxResponseMode::ONLY_NAMES)
    end

    private

    def _parse_uri_script(script_id, path = nil)
      _parse_uri('/api/v2/scripts/' + URI.encode_www_form_component(script_id) + (path.nil? ? '' : "/#{path}"))
    end

    def _to_object(response, model)
      body = response.body

      data = JSON.parse("[#{body}]", symbolize_names: true)[0]
      model.build_from_hash(data)
    end

    def _invoke_script(script_id, params: nil)
      uri = _parse_uri_script(script_id, 'invoke')

      script_invocation_params = InfluxDB2::ScriptInvocationParams.new(params: params)
      _request_json(script_invocation_params.to_body.to_json, uri, headers: { 'Accept' => 'application/json' })
    end
  end
end
