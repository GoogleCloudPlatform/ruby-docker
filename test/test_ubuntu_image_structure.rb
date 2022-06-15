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

require_relative "helper"
require "json"

# Runs structure tests defined in test_base_image.json locally.

class TestUbuntuImageStructure < ::Minitest::Test
  include Helper

  BASE_DIR = ::File.dirname ::File.dirname __FILE__
  CONFIG_FILE = ::File.join BASE_DIR, "ruby-#{Helper.os_name}/structure-test.json"
  CONFIG_DATA = ::JSON.load ::IO.read CONFIG_FILE

  CONFIG_DATA["commandTests"].each do |test_config|
    define_method test_config["name"] do
      command_array = test_config["command"]
      binary = command_array.shift
      command = command_array.map{ |a| "'#{a}'" }.join(" ")
      expectations = test_config["expectedOutput"].map { |e| ::Regexp.new e }
      assert_docker_output \
          "--entrypoint=#{binary} ruby-#{Helper.os_name} #{command}",
          expectations
    end
  end

end
