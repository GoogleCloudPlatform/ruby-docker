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
require "fileutils"

require_relative "../ruby-generate-dockerfile/app/app_config.rb"


class TestAppConfig < ::Minitest::Test
  EMPTY_HASH = {}.freeze
  EMPTY_ARRAY = [].freeze
  EMPTY_STRING = ''.freeze
  DEFAULT_CONFIG_NO_ENTRYPOINT = "env: flex\nruntime: ruby\n"
  DEFAULT_CONFIG =
    "env: flex\nruntime: ruby\nentrypoint: bundle exec ruby start.rb\n"

  TEST_DIR = ::File.dirname __FILE__
  CASES_DIR = ::File.join TEST_DIR, "app_config"
  TMP_DIR = ::File.join TEST_DIR, "tmp"

  def setup_test dir: nil, config: DEFAULT_CONFIG,
                 config_file: nil, project: nil
    ::Dir.chdir TEST_DIR
    ::FileUtils.rm_rf TMP_DIR
    if dir
      full_dir = ::File.join CASES_DIR, dir
      ::FileUtils.cp_r full_dir, TMP_DIR
    else
      ::FileUtils.mkdir TMP_DIR
    end
    ::ENV["GAE_APPLICATION_YAML_PATH"] = config_file
    ::ENV["PROJECT_ID"] = project
    config_path = ::File.join TMP_DIR, config_file || "app.yaml"
    if config
      ::File.open config_path, "w" do |file|
        file.write config
      end
    end
    @app_config = AppConfig.new TMP_DIR
  end

  def test_empty_directory_with_config
    setup_test
    assert_equal TMP_DIR, @app_config.workspace_dir
    assert_equal "./app.yaml", @app_config.app_yaml_path
    assert_nil @app_config.project_id
    assert_equal "(unknown)", @app_config.project_id_for_display
    assert_equal "my-project-id", @app_config.project_id_for_example
    assert_equal "default", @app_config.service_name
    assert_equal EMPTY_HASH, @app_config.env_variables
    assert_equal EMPTY_ARRAY, @app_config.cloud_sql_instances
    assert_equal EMPTY_ARRAY, @app_config.build_scripts
    assert_equal EMPTY_HASH, @app_config.runtime_config
    assert_equal "exec bundle exec ruby start.rb", @app_config.entrypoint
    assert_equal EMPTY_ARRAY, @app_config.install_packages
    assert_equal EMPTY_STRING, @app_config.ruby_version
    refute @app_config.has_gemfile?
  end

  def test_basic_app_yaml
    config = <<~CONFIG
      env: flex
      runtime: ruby
      entrypoint: bundle exec bin/rails s
      env_variables:
        VAR1: value1
        VAR2: value2
        VAR3: 123
      beta_settings:
        cloud_sql_instances: cloud-sql-instance-name,instance2
      runtime_config:
        foo: bar
        packages: libgeos
        build: bundle exec rake hello
    CONFIG
    setup_test config: config
    assert_equal({"VAR1" => "value1", "VAR2" => "value2", "VAR3" => "123"},
                 @app_config.env_variables)
    assert_equal ["cloud-sql-instance-name", "instance2"],
                 @app_config.cloud_sql_instances
    assert_equal ["bundle exec rake hello"], @app_config.build_scripts
    assert_equal "exec bundle exec bin/rails s", @app_config.entrypoint
    assert_equal ["libgeos"], @app_config.install_packages
    assert_equal "bar", @app_config.runtime_config["foo"]
  end

  def test_complex_entrypoint
    config = <<~CONFIG
      env: flex
      runtime: ruby
      entrypoint: cd myapp; bundle exec bin/rails s
    CONFIG
    setup_test config: config
    assert_equal "cd myapp; bundle exec bin/rails s", @app_config.entrypoint
  end

  def test_entrypoint_already_exec
    config = <<~CONFIG
      env: flex
      runtime: ruby
      entrypoint: exec bundle exec bin/rails s
    CONFIG
    setup_test config: config
    assert_equal "exec bundle exec bin/rails s", @app_config.entrypoint
  end

  def test_rails_default_build
    setup_test dir: "rails"
    assert_equal ["bundle exec rake assets:precompile || true"],
                 @app_config.build_scripts
  end

  def test_rails_and_dotenv_default_build
    config = <<~CONFIG
      env: flex
      runtime: ruby
      entrypoint: bundle exec bin/rails s
      runtime_config:
        dotenv_config: my-config
    CONFIG
    setup_test dir: "rails", config: config
    assert_equal \
      [
        "bundle exec rake assets:precompile || true",
        "gem install rcloadenv && rbenv rehash && rcloadenv my-config > .env"
      ],
      @app_config.build_scripts
  end

  def test_ruby_version
    setup_test dir: "ruby-version"
    assert_equal "2.0.99", @app_config.ruby_version
  end

  def test_gemfile_old_name
    setup_test dir: "gemfile-old"
    assert @app_config.has_gemfile?
  end

  def test_gemfile_configru
    setup_test dir: "gemfile-rack", config: DEFAULT_CONFIG_NO_ENTRYPOINT
    assert @app_config.has_gemfile?
    assert_equal "exec bundle exec rackup -p $PORT", @app_config.entrypoint
  end

  def test_config_missing
    ex = assert_raises AppConfig::Error do
      setup_test config: nil
    end
    assert_match %r{Could not read app engine config file:}, ex.message
  end

  def test_needs_entrypoint
    ex = assert_raises AppConfig::Error do
      setup_test config: DEFAULT_CONFIG_NO_ENTRYPOINT
    end
    assert_match %r{Please specify an entrypoint}, ex.message
  end

  def test_illegal_env_name
    config = <<~CONFIG
      env: flex
      runtime: ruby
      entrypoint: bundle exec ruby hello.rb
      env_variables:
        VAR-1: value1
    CONFIG
    ex = assert_raises AppConfig::Error do
      setup_test config: config
    end
    assert_equal "Illegal environment variable name: \"VAR-1\"",
      ex.message
  end

  def test_illegal_build_command
    config = <<~CONFIG
      env: flex
      runtime: ruby
      entrypoint: bundle exec ruby hello.rb
      runtime_config:
        build: "multiple\\nlines"
    CONFIG
    ex = assert_raises AppConfig::Error do
      setup_test config: config
    end
    assert_equal "Illegal newline in build command: \"multiple\\nlines\"",
      ex.message
  end

  def test_dotenv_clashes_with_custom_build
    config = <<~CONFIG
      env: flex
      runtime: ruby
      entrypoint: bundle exec ruby hello.rb
      runtime_config:
        build: ["bundle exec rake hello"]
        dotenv_config: my-config
    CONFIG
    ex = assert_raises AppConfig::Error do
      setup_test config: config
    end
    assert_match /^The `dotenv_config` setting conflicts with the `build`/,
      ex.message
  end

  def test_illegal_sql_instances
    config = <<~CONFIG
      env: flex
      runtime: ruby
      entrypoint: bundle exec ruby hello.rb
      beta_settings:
        cloud_sql_instances: bad!instance
    CONFIG
    ex = assert_raises AppConfig::Error do
      setup_test config: config
    end
    assert_equal "Illegal cloud sql instance name: \"bad!instance\"",
      ex.message
  end

  def test_illegal_entrypoint
    config = <<~CONFIG
      env: flex
      runtime: ruby
      entrypoint: "multiple\\nlines"
    CONFIG
    ex = assert_raises AppConfig::Error do
      setup_test config: config
    end
    assert_equal "Illegal newline in entrypoint: \"multiple\\nlines\"",
      ex.message
  end

  def test_illegal_debian_packages
    config = <<~CONFIG
      env: flex
      runtime: ruby
      entrypoint: bundle exec ruby hello.rb
      runtime_config:
        packages: bad!package
    CONFIG
    ex = assert_raises AppConfig::Error do
      setup_test config: config
    end
    assert_equal "Illegal debian package name: \"bad!package\"",
      ex.message
  end

  def test_illegal_ruby_version
    ex = assert_raises AppConfig::Error do
      setup_test dir: "bad-ruby-version"
    end
    assert_equal "Illegal ruby version: \"bad!version\"",
      ex.message
  end
end
