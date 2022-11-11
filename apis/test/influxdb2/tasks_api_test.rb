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
require 'base_api_test'
require 'test_helper'

class TasksApiTest < BaseApiTests
  def setup
    super
    @client.create_tasks_api.get_tasks.tasks.each do |task|
      next unless task.name.end_with?('_TEST')

      @client.create_tasks_api.delete_tasks_id(task.id)
    end
  end

  def test_create_task
    name = generate_name('task')
    flux = "option task = {name: \"#{name}\", every: 1h}

from(bucket: \"telegraf\")
 |> range(start: -1h)
 |> filter(fn: (r) => r._measurement == \"cpu\")
 |> filter(fn: (r) => r._field == \"usage_system\")"

    request = InfluxDB2::API::TaskCreateRequest.new(org_id: @my_org.id,
                                                    description: 'This task testing API',
                                                    flux: flux,
                                                    status: InfluxDB2::API::TaskStatusType::ACTIVE)

    task = @client.create_tasks_api.post_tasks(request)

    refute_nil task.id
    assert_equal name, task.name
    assert_equal @my_org.name, task.org
    assert_equal @my_org.id, task.org_id
    assert_equal 'This task testing API', task.description
    assert_equal InfluxDB2::API::TaskStatusType::ACTIVE, task.status
    assert_equal flux, task.flux
  end

  def test_update_task
    task = _create_task

    request = InfluxDB2::API::TaskUpdateRequest.new(flux: task.flux,
                                                    description: 'Updated description for testing Task')
    task = @client.create_tasks_api.patch_tasks_id(task.id, request)

    assert_equal 'Updated description for testing Task', task.description
  end

  def test_list_task
    task = _create_task

    tasks = @client.create_tasks_api.get_tasks.tasks
    assert_equal 1, tasks.length
    assert_equal task.name, tasks[0].name
  end

  def test_delete_task
    task = _create_task

    tasks = @client.create_tasks_api.get_tasks.tasks
    assert_equal 1, tasks.length

    @client.create_tasks_api.delete_tasks_id(task.id)

    tasks = @client.create_tasks_api.get_tasks.tasks
    assert_equal 0, tasks.length
  end

  private

  def _create_task
    flux = "option task = {name: \"#{generate_name('task')}\", every: 1h}

from(bucket: \"telegraf\")
 |> range(start: -1h)
 |> filter(fn: (r) => r._measurement == \"cpu\")
 |> filter(fn: (r) => r._field == \"usage_system\")"

    request = InfluxDB2::API::TaskCreateRequest.new(org_id: @my_org.id,
                                                    flux: flux,
                                                    status: InfluxDB2::API::TaskStatusType::ACTIVE)

    @client.create_tasks_api.post_tasks(request)
  end
end
