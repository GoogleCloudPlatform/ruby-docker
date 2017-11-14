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

# Tests of the supported ruby versions. Ensures that all supported ruby
# versions can be installed and will execute.

class TestRubyVersions < ::Minitest::Test

  COMPLETE_VERSIONS = [
    # 2.0 is obsolete, but we keep it for testing patchlevel notation and
    # installation from source.
    "2.0.0-p648",
    # 2.1.x versions are obsolete, but the GCP prebuilt binaries are still
    # present. We retain one test to track how it behaves.
    "2.1.10",
    # 2.2.x versions are currently supported.
    "2.2.0",
    "2.2.1",
    "2.2.2",
    "2.2.3",
    "2.2.4",
    "2.2.5",
    "2.2.6",
    "2.2.7",
    "2.2.8",
    # 2.3.x versions are currently supported.
    "2.3.0",
    "2.3.1",
    "2.3.2",
    "2.3.3",
    "2.3.4",
    "2.3.5",
    # 2.4.x versions are currently supported.
    "2.4.0",
    "2.4.1",
    "2.4.2",
    # Temporary test for 2.5 previews
    "2.5.0-preview1",
    # Test for no requested version (i.e. fall back to default)
    ""
  ]

  FASTER_VERSIONS = [
    # Test only the latest patch of each supported minor version, plus the
    # case of no requested version.
    "2.2.8",
    "2.3.5",
    "2.4.2",
    ""
  ]


  VERSIONS = ::ENV["FASTER_TESTS"] ? FASTER_VERSIONS : COMPLETE_VERSIONS

  DOCKERFILE = <<~DOCKERFILE_CONTENT
    FROM ruby-base

    ARG REQUESTED_RUBY_VERSION=""
    ARG DEBIAN_FRONTEND=noninteractive

    # This matches dockerfile commands generated by gcloud for ruby apps
    RUN if test -n "$REQUESTED_RUBY_VERSION" -a \
            ! -x /rbenv/versions/$REQUESTED_RUBY_VERSION/bin/ruby; then \
          (apt-get update -y \
            && apt-get install -y -q ^gcp-ruby-${REQUESTED_RUBY_VERSION}$) \
          || (cd /rbenv/plugins/ruby-build \
            && git pull \
            && rbenv install -s $REQUESTED_RUBY_VERSION) \
          && rbenv global $REQUESTED_RUBY_VERSION \
          && (bundle version || gem install bundler --version $BUNDLER_VERSION) \
          && apt-get clean \
          && rm -f /var/lib/apt/lists/*_*; \
        fi
    ENV RBENV_VERSION=${REQUESTED_RUBY_VERSION:-$RBENV_VERSION}

    ENTRYPOINT []
    CMD ruby --version
  DOCKERFILE_CONTENT


  include TestHelper

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
      file.write DOCKERFILE
    end
    ::Dir.chdir TMP_DIR do |dir|
      build_docker_image(
          "--build-arg REQUESTED_RUBY_VERSION=#{version}",
          mangled_version) do |image|
        assert_docker_output(image, /ruby\s#{version_output}/, mangled_version)
      end
    end
  end

end
