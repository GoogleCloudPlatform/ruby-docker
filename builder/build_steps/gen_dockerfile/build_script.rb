#!/rbenv/shims/ruby

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

require_relative "build_info.rb"

class BuildScript
  DEFAULT_BASE_IMAGE_TAG = "latest"
  DEFAULT_ENTRYPOINT = "bundle exec rackup -p $PORT"

  def initialize args
    @build = BuildInfo.new args
    @build.banner "ruby-gen-dockerfile", <<~DESCRIPTION
      Generates a Dockerfile for this Ruby application.
    DESCRIPTION
  end

  def main
    base_image_tag =
        @build.runtime_config["base_image_tag"] || DEFAULT_BASE_IMAGE_TAG
    packages = @build.runtime_config["packages"] || []
    entrypoint =
        @build.runtime_config["entrypoint"] ||
        @build.app_yaml["entrypoint"] ||
        DEFAULT_ENTRYPOINT
    @build.write_file "Dockerfile",
                      base_image_tag: base_image_tag,
                      ruby_version: @build.ruby_version,
                      packages: packages,
                      entrypoint: entrypoint
    @build.write_file ".dockerignore"
    @build.cleanup_file_perms
  end
end

BuildScript.new(::ARGV).main
