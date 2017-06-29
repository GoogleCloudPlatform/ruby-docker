# Copyright 2017 Google Inc. All rights reserved.
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
require "fileutils"

require_relative "../build_steps/shared/build_info.rb"


class TestBuildInfo < ::Minitest::Test
  EMPTY_HASH = {}.freeze
  EMPTY_ARRAY = [].freeze
  EMPTY_STRING = ''.freeze

  TEST_DIR = ::File.dirname __FILE__
  CASES_DIR = ::File.join TEST_DIR, "build_info"
  TMP_DIR = ::File.join TEST_DIR, "tmp"

  def setup_test dir: nil, config: nil
    ::Dir.chdir TEST_DIR
    ::FileUtils.rm_rf TMP_DIR
    if dir
      full_dir = ::File.join CASES_DIR, dir
      ::FileUtils.cp_r full_dir, TMP_DIR
    else
      ::FileUtils.mkdir TMP_DIR
      if config
        config_path = ::File.join TMP_DIR, "app.yaml"
        ::File.open config_path, "w" do |file|
          file.write config
        end
      end
    end
    @build = BuildInfo.new ["-t", "--workspace-dir=#{TMP_DIR}",
                            "--rbenv-dir=/rbenv", "--enable-packages"]
  end

  def test_empty_directory
    setup_test
    assert @build.testing
    assert_equal TMP_DIR, @build.workspace_dir
    assert_equal "/rbenv", @build.rbenv_dir
    assert_equal "app.yaml", @build.app_yaml_path
    assert_equal EMPTY_HASH, @build.env_variables
    assert_equal EMPTY_ARRAY, @build.cloud_sql_instances
    assert_equal EMPTY_ARRAY, @build.build_scripts
    assert_equal EMPTY_HASH, @build.runtime_config
    assert_equal "exec bundle exec rackup -p $PORT", @build.entrypoint
    assert_equal EMPTY_ARRAY, @build.install_packages
    assert_equal EMPTY_STRING, @build.ruby_version
  end

  def test_basic_app_yaml
    config = <<~CONFIG
      env: flex
      runtime: ruby
      entrypoint: bundle exec bin/rails s
      env_variables:
        VAR1: value1
        VAR2: value2
      beta_settings:
        cloud_sql_instances: cloud-sql-instance-name
      runtime_config:
        foo: bar
        packages: libgeos
      lifecycle:
        build: bundle exec rake hello
    CONFIG
    setup_test config: config
    assert_equal({"VAR1" => "value1", "VAR2" => "value2"}, @build.env_variables)
    assert_equal ["cloud-sql-instance-name"], @build.cloud_sql_instances
    assert_equal ["bundle exec rake hello"], @build.build_scripts
    assert_equal "exec bundle exec bin/rails s", @build.entrypoint
    assert_equal ["libgeos"], @build.install_packages
    assert_equal "bar", @build.runtime_config["foo"]
  end

  def test_complex_entrypoint
    config = <<~CONFIG
      env: flex
      runtime: ruby
      entrypoint: cd myapp; bundle exec bin/rails s
    CONFIG
    setup_test config: config
    assert_equal "cd myapp; bundle exec bin/rails s", @build.entrypoint
  end

  def test_entrypoint_already_exec
    config = <<~CONFIG
      env: flex
      runtime: ruby
      entrypoint: exec bundle exec bin/rails s
    CONFIG
    setup_test config: config
    assert_equal "exec bundle exec bin/rails s", @build.entrypoint
  end

  def test_rails_default_build
    setup_test dir: "rails"
    assert_equal ["bundle exec rake assets:precompile || true"],
                 @build.build_scripts
  end

  def test_ruby_version
    setup_test dir: "ruby-version"
    assert_equal "2.0.99", @build.ruby_version
  end
end
