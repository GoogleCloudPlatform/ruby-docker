# Copyright 2016 Google Inc. All rights reserved.
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
require "fileutils"


class TestSampleApps < ::Minitest::Test
  include TestHelper

  TEST_DIR = ::File.dirname __FILE__
  CASES_DIR = ::File.join TEST_DIR, "builder_cases"
  APPS_DIR = ::File.join TEST_DIR, "sample_apps"
  TMP_DIR = ::File.join TEST_DIR, "tmp"

  def test_rack_app
    run_app_test "rack_app" do |image|
      assert_docker_output "#{image} test ! -d /app/public/assets", nil
    end
  end

  def test_sinatra1_app
    run_app_test "sinatra1_app" do |image|
      assert_docker_output "#{image} test ! -d /app/public/assets", nil
    end
  end

  def test_rails5_app
    run_app_test "rails5_app" do |image|
      assert_docker_output "#{image} test -d /app/public/assets", nil
    end
  end

  def test_rails4_app
    run_app_test "rails4_app" do |image|
      assert_docker_output "#{image} test -d /app/public/assets", nil
    end
  end

  def run_app_test app_name
    puts "**** Testing app: #{app_name}"

    app_dir = ::File.join APPS_DIR, app_name
    case_dir = ::File.join CASES_DIR, app_name
    ::FileUtils.rm_rf TMP_DIR
    ::FileUtils.cp_r app_dir, TMP_DIR
    ::Dir.glob "#{case_dir}/*", ::File::FNM_DOTMATCH do |path|
      ::FileUtils.cp_r path, TMP_DIR unless ::File.basename(path) =~ /^\.\.?$/
    end

    assert_docker_output \
        "-v #{TMP_DIR}:/workspace -w /workspace ruby-generate-dockerfile" \
          " -t --base-image=gcr.io/google-appengine/ruby:latest" \
          " --build-tools-image=ruby-build-tools",
        nil
    ::Dir.chdir TMP_DIR do
      build_docker_image "--no-cache" do |image|
        yield image
        run_docker_daemon "-p 8080:8080 #{image}" do |container|
          assert_cmd_output \
              "docker exec #{container} curl -s -S http://127.0.0.1:8080",
              "Hello World!", 10
        end
      end
    end
  end
end
