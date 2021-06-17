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
  # Exponential random write retry.
  class WriteRetry
    @error_msg_prefix = 'Error with options to with_retries:'

    # @param [Hash] options the retry options.
    # @option options [Integer] :max_retries (5) The maximum number of times to run the block.
    # @option options [Integer] :retry_interval (5000) number of milliseconds to retry unsuccessful write.
    # @option options [Integer] :max_retry_delay (125_000) maximum delay when retrying write in milliseconds.
    # @option options [Integer] :max_retry_time (180_000) maximum total retry timeout in milliseconds.
    # @option options [Integer] :exponential_base base for the exponential retry delay
    # @option options [Integer] :jitter_delay random milliseconds added to write interval
    def initialize(options = {})
      @api_client = options[:api_client]
      @max_retries = options[:max_retries] || 5
      raise "#{@error_msg_prefix} :max_retries must be greater than 0." unless @max_retries > 0

      @retry_interval = options[:retry_interval] || 5_000
      @max_retry_delay = options[:max_retry_delay] || 125_000
      @max_retry_time = options[:max_retry_time] || 180_000
      @exponential_base = options[:exponential_base] || 2
      @jitter_interval = options[:jitter_interval] || 0
      raise "#{@error_msg_prefix} :retry_interval cannot be greater than :max_retry_delay." if
        @retry_interval > @max_retry_delay
    end

    def get_backoff_time(attempts)
      range_start = @retry_interval
      range_stop = @retry_interval * @exponential_base

      i = 1
      while i < attempts
        i += 1
        range_start = range_stop
        range_stop *= @exponential_base
        break if range_stop > @max_retry_delay
      end

      range_stop = @max_retry_delay if range_stop > @max_retry_delay
      range_start + (range_stop - range_start) * rand
    end

    # Runs the supplied code block with a exponential backoff retry strategy.
    def retry
      raise "#{@error_msg_prefix} must be passed a block" unless block_given?

      attempts = 0
      start_time = Time.now
      begin
        attempts += 1
        yield attempts
      rescue InfluxError => e
        if attempts > @max_retries
          @api_client.log(:error, 'Maximum retry attempts reached.')
          raise e
        end

        if (Time.now - start_time) * 1000 > @max_retry_time
          @api_client.log(:error, "Maximum retry time #{@max_retry_time} ms exceeded")
          raise e
        end

        raise e if (e.code.nil? || e.code.to_i < 429) && !_connection_error(e.original)

        timeout = if e.retry_after.nil? || e.retry_after.empty?
                    get_backoff_time(attempts)
                  else
                    (e.retry_after.to_f * 1000) + @jitter_interval * rand
                  end

        message = 'The retriable error occurred during writing of data. '\
    "Reason: '#{e.message}'. Retry in: #{timeout.to_f / 1000}s."

        @api_client.log(:warn, message)
        sleep timeout / 1000
        retry
      end
    end

    def _connection_error(error)
      InfluxError::HTTP_ERRORS.any? { |c| error.instance_of? c }
    end
  end
end
