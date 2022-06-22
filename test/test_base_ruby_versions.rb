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
  PREBUILT_RUBY_VERSIONS = ::ENV["PREBUILT_RUBY_VERSIONS"].to_s.split(",")
  PRIMARY_RUBY_VERSIONS = ::ENV["PRIMARY_RUBY_VERSIONS"].to_s.split(",")
  PREBUILT_RUBY_IMAGE_BASE = ::ENV["PREBUILT_RUBY_IMAGE_BASE"]
  PREBUILT_RUBY_IMAGE_TAG = ::ENV["PREBUILT_RUBY_IMAGE_TAG"]
  BUNDLER1_VERSION = ::ENV["BUNDLER1_VERSION"]
  BUNDLER2_VERSION = ::ENV["BUNDLER2_VERSION"]

  if ::ENV["FASTER_TESTS"] || ::ENV["USE_LOCAL_PREBUILT"]
    VERSIONS = PRIMARY_RUBY_VERSIONS & PREBUILT_RUBY_VERSIONS
  else
    # Out of the prebuilt list, choose all patches of current versions (i.e.
    # whose minor version is reflected in the primaries) but only the latest
    # patch of all other versions. Also add 2.0.0-p648 to test patchlevel
    # notation and installation from source.
    VERSIONS = PREBUILT_RUBY_VERSIONS.map do |version|
      if version =~ /^(\d+\.\d+)/
        minor = Regexp.last_match[1]
        next version if PRIMARY_RUBY_VERSIONS.any? { |v| v.start_with? minor }
        PREBUILT_RUBY_VERSIONS.map do |v|
          if v.start_with? minor
            Gem::Version.new v
          end
        end.compact.sort.last.to_s
      end
    end.compact.uniq + ["2.0.0-p648"]
  end

  DOCKERFILE_SELFBUILT = <<~DOCKERFILE_CONTENT
    FROM $OS_IMAGE
    ARG ruby_version
    COPY --from=ruby-build-tools /opt/gems/ /opt/gems/
    RUN rbenv install -s ${ruby_version} \
        && rbenv global ${ruby_version} \
        && rbenv rehash \
        && (gem install /opt/gems/bundler-#{BUNDLER1_VERSION}.gem ; \
            gem install /opt/gems/bundler-#{BUNDLER2_VERSION}.gem ; \
            rbenv rehash)
    CMD ruby --version
  DOCKERFILE_CONTENT

  DOCKERFILE_PREBUILT = <<~DOCKERFILE_CONTENT
    FROM ruby-#{Helper.os_name}
    ARG ruby_version
    COPY --from=ruby-build-tools /opt/gems/ /opt/gems/
    COPY --from=$PREBUILT_RUBY_IMAGE \
         /opt/rbenv/versions/${ruby_version} \
         /opt/rbenv/versions/${ruby_version}
    RUN rbenv global ${ruby_version} \
        && rbenv rehash \
        && (gem install /opt/gems/bundler-#{BUNDLER1_VERSION}.gem ; \
            gem install /opt/gems/bundler-#{BUNDLER2_VERSION}.gem ; \
            rbenv rehash)
    CMD ruby --version
  DOCKERFILE_CONTENT

  include Helper

  TMP_DIR = ::File.join __dir__, "tmp"

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
      if PREBUILT_RUBY_VERSIONS.include? version
        prebuilt_image = "#{PREBUILT_RUBY_IMAGE_BASE}#{version}:#{PREBUILT_RUBY_IMAGE_TAG}"
        file.write DOCKERFILE_PREBUILT.sub("$PREBUILT_RUBY_IMAGE", prebuilt_image)
      else
        os_image = "ruby-#{Helper.os_name}"
        os_image = "#{os_image}-ssl10" if version < "2.4"
        file.write DOCKERFILE_SELFBUILT.sub("$OS_IMAGE", os_image)
      end
    end
    ::Dir.chdir TMP_DIR do |dir|
      build_docker_image(
          "--build-arg ruby_version=#{version}",
          mangled_version) do |image|
        assert_docker_output(image, /ruby\s#{version_output}/, "ruby-#{mangled_version}")
        assert_docker_output("#{image} bundle version", /Bundler version/, "bundler-#{mangled_version}")
      end
    end
  end

end
