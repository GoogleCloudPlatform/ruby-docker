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

require "json"
require_relative "build_info.rb"

class BuildScript
  DEFAULT_BASE_IMAGE = "gcr.io/google-appengine/ruby:staging"

  def initialize args
    @base_image = DEFAULT_BASE_IMAGE
    @build = BuildInfo.new args do |opts|
      opts.on "--base-image=IMAGE" do |image|
        @base_image = image
      end
    end
    @build.banner "ruby-gen-dockerfile", <<~DESCRIPTION
      Generates a Dockerfile for this Ruby application.
    DESCRIPTION
  end

  def main
    @build.write_file "Dockerfile",
                      base_image: @base_image,
                      ruby_version: @build.ruby_version,
                      packages: @build.install_packages.join(' '),
                      entrypoint: @build.entrypoint
    unless @build.file_exists? ".dockerignore"
      @build.write_file ".dockerignore",
                        gae_application_yaml_path: @build.app_yaml_path
    end
    @build.cleanup_file_perms
  end
end

BuildScript.new(::ARGV).main
