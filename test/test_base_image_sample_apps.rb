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

# Tests of a bunch of sample apps. Treats every subdirectory of the test
# directory that contains a Dockerfile as a sample app. Builds the docker
# image, runs the server, and hits the root of the server, expecting the
# string "Hello World!" to be returned.
#
# This is supposed to exercise the base image extended in various ways, so
# the sample app Dockerfiles should all inherit FROM the base image, which
# will be called "ruby-base".

class TestBaseImageSampleApps < ::Minitest::Test
  include Helper

  TEST_DIR = ::File.dirname __FILE__
  APPS_DIR = ::File.join TEST_DIR, "sample_apps"
  TMP_DIR = ::File.join TEST_DIR, "tmp"


  unless ::ENV["FASTER_TESTS"]

    def test_rack_app
      run_app_test "rack_app", <<~DOCKERFILE
        FROM ruby-base
        COPY . /app/
        RUN bundle install && rbenv rehash
        ENTRYPOINT bundle exec rackup -p 8080 -E production config.ru
      DOCKERFILE
    end

    def test_rails4_app
      run_app_test "rails4_app", <<~DOCKERFILE
        FROM ruby-base
        COPY . /app/
        RUN bundle install && rbenv rehash
        ENV SECRET_KEY_BASE=a12345
        ENTRYPOINT bundle exec bin/rails server -p 8080
      DOCKERFILE
    end

  end

  def test_rails5_app
    run_app_test "rails5_app", <<~DOCKERFILE
      FROM ruby-base
      COPY . /app/
      RUN bundle install && rbenv rehash
      ENV SECRET_KEY_BASE=a12345
      ENTRYPOINT bundle exec bin/rails server -p 8080
    DOCKERFILE
  end

  def test_sinatra1_app
    run_app_test "sinatra1_app", <<~DOCKERFILE
      FROM ruby-base
      COPY . /app/
      RUN bundle install && rbenv rehash
      ENV GOOGLE_CLOUD_PROJECT=""
      ENTRYPOINT bundle exec ruby myapp.rb -p 8080
    DOCKERFILE
  end


  def run_app_test app_name, dockerfile
    puts "**** Testing app for base image: #{app_name}"

    app_dir = ::File.join APPS_DIR, app_name
    assert_cmd_succeeds "rm -rf #{TMP_DIR}"
    assert_cmd_succeeds "cp -r #{app_dir} #{TMP_DIR}"
    dockerfile_path = ::File.join TMP_DIR, "Dockerfile"
    ::File.open dockerfile_path, "w" do |file|
      file.write dockerfile
    end

    ::Dir.chdir TMP_DIR do |dir|
      build_docker_image "", app_name do |image|
        run_docker_daemon "-p 8080:8080 #{image}" do |container|
          assert_cmd_output \
              "docker exec #{container} curl -s -S http://127.0.0.1:8080",
              "Hello World!", 10
        end
      end
    end
  end

end
