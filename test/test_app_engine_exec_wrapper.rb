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

class TestAppEngineExecWrapper < ::Minitest::Test
  include Helper

  def test_simple
    run_test "simple", {VAR1: "value1", VAR2: "value2"}, "sql:1:2:3"
  end

  def test_no_cloudsql
    run_test "no_cloudsql", {VAR1: "value1", VAR2: "value2"}
  end

  WRAPPER_TESTS_DIR = "#{::File.dirname __FILE__}/app_engine_exec_wrapper"

  def run_test test_case, env, sql_instances=nil
    ::Dir.chdir "#{WRAPPER_TESTS_DIR}/#{test_case}" do
      build_docker_image("--no-cache") do |image|
        env_params = env.map{ |k, v| "-e #{k}=#{v}" }.join " "
        sql_params = Array(sql_instances).map{ |s| "-s #{s}" }.join ' '
        assert_cmd_succeeds "docker run --rm" +
          " --volume=/var/run/docker.sock:/var/run/docker.sock" +
          " app-engine-exec-harness" +
          " -i #{image} #{env_params} #{sql_params}" +
          " -x -P -n default"
      end
    end
  end
end
