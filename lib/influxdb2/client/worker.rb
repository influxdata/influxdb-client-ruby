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
  # Worker for handling write batching queue
  #
  class Worker
    def initialize(api_client, write_options)
      @api_client = api_client
      @write_options = write_options

      @queue = Queue.new
      @queue_event = Queue.new

      @queue_event.push(true)

      @thread_flush = Thread.new do
        until api_client.closed
          sleep @write_options.flush_interval.to_f / 1_000
          _check_background_queue
        end
      end
      @thread_flush.abort_on_exception = @write_options.batch_abort_on_exception

      @thread_size = Thread.new do
        until api_client.closed
          _check_background_queue(size: true) if @queue.length >= @write_options.batch_size
          sleep 0.01
        end
      end
      @thread_size.abort_on_exception = @write_options.batch_abort_on_exception
    end

    def push(payload)
      if payload.respond_to? :each
        payload.each do |item|
          push(item)
        end
      else
        @queue.push(payload)
      end
    end

    def flush_all
      _check_background_queue until @queue.empty?
    end

    private

    def _check_background_queue(size: false)
      @queue_event.pop
      data = {}
      points = 0

      if size && @queue.length < @write_options.batch_size
        @queue_event.push(true)
        return
      end

      while (points < @write_options.batch_size) && !@queue.empty?
        begin
          item = @queue.pop(true)
          key = item.key
          data[key] = [] unless data.key?(key)
          data[key] << item.data
          points += 1
        rescue ThreadError
          @queue_event.push(true)
          return
        end
      end

      begin
        _write(data) unless data.values.flatten.empty?
      ensure
        @queue_event.push(true)
      end
    end

    def _write(data)
      data.each do |key, points|
        _write_raw(key, points)
      end
    end

    def _write_raw(key, points)
      write_retry = InfluxDB2::WriteRetry.new(
        api_client: @api_client,
        max_retries: @write_options.max_retries,
        exponential_base: @write_options.exponential_base,
        retry_interval: @write_options.retry_interval,
        max_retry_delay: @write_options.max_retry_delay,
        max_retry_time: @write_options.max_retry_time
      )

      if @write_options.jitter_interval > 0
        jitter_delay = (@write_options.jitter_interval.to_f / 1_000) * rand
        sleep jitter_delay
      end

      write_retry.retry do
        @api_client.write_raw(points.join("\n"), precision: key.precision, bucket: key.bucket, org: key.org)
      end
    end
  end
end
