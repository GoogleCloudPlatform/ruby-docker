#!/usr/bin/env ruby

# Copyright 2017 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


class FakeCloudSqlProxy
  def initialize args
    @dir = nil
    @instances = []
    args.each do |arg|
      case arg
      when /^-dir=(.*)$/
        @dir = $1
      when /^-instances=(.*)$/
        @instances += $1.split ","
      else
        abort "Unknown arg: #{arg}"
      end
    end
  end

  def run
    puts "Starting fake_cloud_sql_proxy"
    abort "Dir not given" unless @dir
    abort "No instances" if @instances.empty?
    sleep(1.0 + 4.0 * rand)
    if @dir
      @instances.each do |instance|
        system "touch #{@dir}/#{instance}"
      end
    end
    puts "Ready for new connections"
  end
end

FakeCloudSqlProxy.new(ARGV).run
