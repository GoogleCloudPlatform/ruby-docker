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
require_relative "../../test/test_helper"
require "fileutils"


class TestSampleApps < ::Minitest::Test
  include TestHelper

  TEST_DIR = ::File.dirname __FILE__
  BASE_DIR = ::File.dirname ::File.dirname TEST_DIR
  CASES_DIR = ::File.join TEST_DIR, "sample_apps"
  APPS_DIR = ::File.join BASE_DIR, "test/sample_apps"
  TMP_DIR = ::File.join TEST_DIR, "tmp"

  def test_rack_app
    run_app_test "rack_app"
    assert_file_contents "#{TMP_DIR}/Dockerfile",
        /CMD \["bundle","exec","rackup","-p","8080"\]/
  end

  def test_sinatra1_app
    run_app_test "sinatra1_app", ruby_version: "2.3.3"
    assert_file_contents "#{TMP_DIR}/Dockerfile",
        /CMD exec bundle exec ruby myapp\.rb -p \$PORT/
  end

  def test_rails5_app
    run_app_test "rails5_app", ruby_version: "2.3.1", has_assets: true
    assert_file_contents "#{TMP_DIR}/Dockerfile",
        /CMD exec bundle exec bin\/rails s/
  end

  def test_rails4_app
    run_app_test "rails4_app", has_assets: true
    assert_file_contents "#{TMP_DIR}/Dockerfile",
        /CMD \["bundle","exec","bin\/rails","s"\]/
  end

  def run_app_test app_name, ruby_version: "", has_assets: false
    puts "**** Testing app: #{app_name}"

    app_dir = ::File.join APPS_DIR, app_name
    case_dir = ::File.join CASES_DIR, app_name
    ::FileUtils.rm_rf TMP_DIR
    ::FileUtils.cp_r app_dir, TMP_DIR
    ::Dir.glob "#{case_dir}/*", ::File::FNM_DOTMATCH do |path|
      ::FileUtils.cp_r path, TMP_DIR unless ::File.basename(path) =~ /^\.\.?$/
    end

    assert_docker_output \
        "-v #{TMP_DIR}:/workspace -w /workspace ruby-gen-dockerfile -t" \
          " --base-image=gcr.io/google-appengine/ruby:my-test-tag",
        nil
    assert_file_contents "#{TMP_DIR}/Dockerfile",
        [
          /ARG REQUESTED_RUBY_VERSION="#{ruby_version}"/,
          /FROM gcr\.io\/google-appengine\/ruby:my-test-tag/
        ]
    assert_file_contents "#{TMP_DIR}/.dockerignore", /Dockerfile/

    assert_docker_output \
        "-v #{TMP_DIR}:/workspace -w /workspace ruby-build-app -t",
        nil
    assert_equal ::File.directory?("#{TMP_DIR}/public/assets"), has_assets
  end
end
