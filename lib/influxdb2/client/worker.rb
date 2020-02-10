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

      @thread_flush = Thread.new do
        until api_client.closed
          sleep @write_options.flush_interval
          check_background_queue
        end
      end

      @thread_size = Thread.new do
        until api_client.closed
          if @queue.length >= @write_options.batch_size
            check_background_queue
            sleep 0.01
          end
        end
      end
    end

    def push(payload)
      @queue.push(payload)
    end

    def check_background_queue
      if @queue_event.empty?
        @queue_event.push(true)

        data = {}
        points = 0

        while points < @write_options.batch_size && !@queue.empty?
          begin
            item = @queue.pop(true)
            key = item.key
            data[key] = [] unless data.has_key?(key)
            data[key] << item.data
            points += 1
          rescue ThreadError
            next
          end
        end

        return if data.values.flatten.empty?

        # write
        write(data)

        @queue_event.pop
      end
    end

    def write(data)
      data.each {|d| puts d}
      puts '----'
    end
  end
end
