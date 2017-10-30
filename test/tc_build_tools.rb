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

require "minitest/autorun"
require_relative "test_helper"


class TestBuildTools < ::Minitest::Test

  include TestHelper

  TEST_DIR = ::File.dirname __FILE__
  TMP_DIR = ::File.join TEST_DIR, "tmp"

  DOCKERFILE = <<~DOCKERFILE_CONTENT
    FROM ruby-base
    COPY --from=ruby-build-tools /build_tools/ /build_tools/
  DOCKERFILE_CONTENT

  def test_build_tools
    assert_cmd_succeeds "rm -rf #{TMP_DIR}"
    assert_cmd_succeeds "mkdir -p #{TMP_DIR}"
    dockerfile_path = ::File.join TMP_DIR, "Dockerfile"
    ::File.open dockerfile_path, "w" do |file|
      file.write DOCKERFILE
    end
    ::Dir.chdir TMP_DIR do
      build_docker_image "--no-cache" do |image|
        assert_docker_output "#{image} /build_tools/nodejs/bin/node --version",
          /^v\d+\.\d+/
        assert_docker_output "#{image} /build_tools/yarn/bin/yarn --version",
          /^\d+\.\d+/
        assert_docker_output "#{image} /build_tools/cloud_sql_proxy --version",
          /Cloud SQL Proxy/
        assert_docker_output \
          "#{image} /build_tools/google-cloud-sdk/bin/gcloud --version",
          /Google Cloud SDK/
        assert_docker_output \
          "#{image} /build_tools/access_cloud_sql --lenient && echo OK",
          /OK/
      end
    end
  end

end
