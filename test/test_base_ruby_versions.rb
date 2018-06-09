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

# Tests of the supported ruby versions. Ensures that all supported ruby
# versions can be installed and will execute.

class TestRubyVersions < ::Minitest::Test

  COMPLETE_VERSIONS = [
    # 2.0 is obsolete, but we keep it for testing patchlevel notation and
    # installation from source.
    "2.0.0-p648",
    # 2.1.x and 2.2.x are obsolete, but the GCP prebuilt binaries are still
    # present. We retain one test per minor version to track how it behaves.
    "2.1.10",
    "2.2.10",
    # 2.3.x versions are currently supported.
    "2.3.0",
    "2.3.1",
    "2.3.2",
    "2.3.3",
    "2.3.4",
    "2.3.5",
    "2.3.6",
    "2.3.7",
    # 2.4.x versions are currently supported.
    "2.4.0",
    "2.4.1",
    "2.4.2",
    "2.4.3",
    "2.4.4",
    # 2.5.x versions are currently supported.
    "2.5.0",
    "2.5.1"
  ]

  FASTER_VERSIONS = [
    # Test only the latest patch of each supported minor version.
    "2.3.7",
    "2.4.4",
    "2.5.1"
  ]

  PREBUILT_VERSIONS = ::ENV["PREBUILT_RUBY_VERSIONS"].to_s.split(",")
  PREBUILT_RUBY_IMAGE_BASE = ::ENV["PREBUILT_RUBY_IMAGE_BASE"]
  PREBUILT_RUBY_IMAGE_TAG = ::ENV["PREBUILT_RUBY_IMAGE_TAG"]

  if ::ENV["FASTER_TESTS"] || ::ENV["USE_LOCAL_PREBUILT"]
    VERSIONS = FASTER_VERSIONS & PREBUILT_VERSIONS
  else
    VERSIONS = COMPLETE_VERSIONS
  end

  DOCKERFILE_SELFBUILT = <<~DOCKERFILE_CONTENT
    FROM ruby-ubuntu16
    ARG ruby_version
    RUN rbenv install -s ${ruby_version} \
        && rbenv global ${ruby_version} \
        && rbenv rehash \
        && (bundle version > /dev/null 2>&1 \
            || gem install bundler --version ${DEFAULT_BUNDLER_VERSION}) \
        && rbenv rehash
    CMD ruby --version
  DOCKERFILE_CONTENT

  DOCKERFILE_PREBUILT = <<~DOCKERFILE_CONTENT
    FROM ruby-ubuntu16
    ARG ruby_version
    COPY --from=$PREBUILT_RUBY_IMAGE \
         /opt/rbenv/versions/${ruby_version} \
         /opt/rbenv/versions/${ruby_version}
    RUN rbenv global ${ruby_version} \
        && rbenv rehash \
        && (bundle version > /dev/null 2>&1 \
            || gem install bundler --version ${DEFAULT_BUNDLER_VERSION}) \
        && rbenv rehash
    CMD ruby --version
  DOCKERFILE_CONTENT


  include Helper

  TEST_DIR = ::File.dirname __FILE__
  TMP_DIR = ::File.join TEST_DIR, "tmp"

  VERSIONS.each do |version|
    mangled_version = version.gsub(".", "_").gsub("-", "_")
    mangled_version = "default_version" if mangled_version == ""
    define_method("test_#{mangled_version}") do
      run_version_test(version, mangled_version)
    end
  end


  def run_version_test(version, mangled_version)
    puts("**** Testing ruby version: #{version}")
    version_output = version.gsub("-", "").gsub(".", "\\.")
    assert_cmd_succeeds "rm -rf #{TMP_DIR}"
    assert_cmd_succeeds "mkdir -p #{TMP_DIR}"
    dockerfile_path = ::File.join TMP_DIR, "Dockerfile"
    ::File.open dockerfile_path, "w" do |file|
      if PREBUILT_VERSIONS.include? version
        prebuilt_image = "#{PREBUILT_RUBY_IMAGE_BASE}#{version}:#{PREBUILT_RUBY_IMAGE_TAG}"
        file.write DOCKERFILE_PREBUILT.sub("$PREBUILT_RUBY_IMAGE", prebuilt_image)
      else
        file.write DOCKERFILE_SELFBUILT
      end
    end
    ::Dir.chdir TMP_DIR do |dir|
      build_docker_image(
          "--build-arg ruby_version=#{version}",
          mangled_version) do |image|
        assert_docker_output(image, /ruby\s#{version_output}/, mangled_version)
      end
    end
  end

end
