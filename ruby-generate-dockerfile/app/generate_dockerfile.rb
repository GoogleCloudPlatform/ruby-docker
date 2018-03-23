#!/rbenv/shims/ruby

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

require "erb"
require "optparse"
require "delegate"

require_relative "app_config.rb"

class GenerateDockerfile
  DEFAULT_WORKSPACE_DIR = "/workspace"
  GENERATOR_DIR = ::File.absolute_path(::File.dirname __FILE__)
  DOCKERIGNORE_PATHS = [
    ".dockerignore",
    "Dockerfile",
    ".git",
    ".hg",
    ".svn"
  ]

  def initialize args
    @workspace_dir = DEFAULT_WORKSPACE_DIR
    @base_image = nil
    @build_tools_image = nil
    @prebuilt_ruby_image_base = nil
    @prebuilt_ruby_image_tag = nil
    @prebuilt_ruby_versions = []
    @default_ruby_version = nil
    @testing = false
    parse_args args
    ::Dir.chdir @workspace_dir
    begin
      @app_config = ::AppConfig.new @workspace_dir
    rescue ::AppConfig::Error => ex
      ::STDERR.puts ex.message
      exit 1
    end
    @timestamp = ::Time.now.utc.strftime "%Y-%m-%d %H:%M:%S UTC"
  end

  def main
    write_dockerfile
    write_dockerignore
    if @testing
      system "chmod -R a+w #{@app_config.workspace_dir}"
    end
  end

  private

  def parse_args(args)
    ::OptionParser.new do |opts|
      opts.on "-t" do
        @testing = true
      end
      opts.on "--workspace-dir=PATH" do |path|
        @workspace_dir = ::File.absolute_path path
      end
      opts.on "--base-image=IMAGE" do |image|
        @base_image = image
      end
      opts.on "--build-tools-image=IMAGE" do |image|
        @build_tools_image = image
      end
      opts.on "--prebuilt-ruby-image-base=BASE" do |base|
        @prebuilt_ruby_image_base = base
      end
      opts.on "--prebuilt-ruby-image-tag=TAG" do |tag|
        @prebuilt_ruby_image_tag = tag
      end
      opts.on "--prebuilt-ruby-versions=VERSIONS" do |versions|
        @prebuilt_ruby_versions = versions.split(",")
      end
      opts.on "--default-ruby-version=VERSION" do |version|
        @default_ruby_version = version
      end
    end.parse! args
  end

  def write_dockerfile
    b = TemplateCallbacks.new(@app_config, @timestamp, @base_image,
                              @build_tools_image, @prebuilt_ruby_image_base,
                              @prebuilt_ruby_image_tag, @prebuilt_ruby_versions,
                              @default_ruby_version).instance_eval{ binding }
    write_path = "#{@app_config.workspace_dir}/Dockerfile"
    if ::File.exist? write_path
      ::STDERR.puts "Unable to generate Dockerfile because one already exists."
      exit 1
    end
    template = ::File.read "#{GENERATOR_DIR}/Dockerfile.erb"
    content = ::ERB.new(template, nil, "<>").result(b)
    ::File.open write_path, "w" do |file|
      file.write content
    end
    puts "Generated Dockerfile"
  end

  def write_dockerignore
    write_path = "#{@app_config.workspace_dir}/.dockerignore"
    if ::File.exist? write_path
      existing_entries = ::IO.readlines write_path
    else
      existing_entries = []
    end
    desired_entries = DOCKERIGNORE_PATHS + [@app_config.app_yaml_path]
    ::File.open write_path, "a" do |file|
      (desired_entries - existing_entries).each do |entry|
        file.puts entry
      end
    end
    if existing_entries.empty?
      puts "Generated .dockerignore"
    else
      puts "Updated .dockerignore"
    end
  end

  class TemplateCallbacks < SimpleDelegator
    def initialize app_config, timestamp, base_image, build_tools_image,
                   prebuilt_ruby_image_base, prebuilt_ruby_image_tag,
                   prebuilt_ruby_versions, default_ruby_version
      @timestamp = timestamp
      @base_image = base_image
      @build_tools_image = build_tools_image
      @prebuilt_ruby_image_base = prebuilt_ruby_image_base
      @prebuilt_ruby_image_tag = prebuilt_ruby_image_tag
      @prebuilt_ruby_versions = prebuilt_ruby_versions
      @default_ruby_version = default_ruby_version
      super app_config
    end

    attr_reader :timestamp
    attr_reader :base_image
    attr_reader :build_tools_image

    def ruby_version
      v = super.to_s
      v.empty? ? @default_ruby_version : v
    end

    def prebuilt_ruby_image
      v = ruby_version
      return nil unless @prebuilt_ruby_versions.include? v
      "#{@prebuilt_ruby_image_base}#{v}:#{@prebuilt_ruby_image_tag}"
    end

    def escape_quoted str
      str.gsub("\\", "\\\\").gsub("\"", "\\\"").gsub("\n", "\\n")
    end

    def render_env hash
      hash.map{ |k,v| "#{k}=\"#{escape_quoted v}\"" }.join(" \\\n    ")
    end
  end
end

::GenerateDockerfile.new(::ARGV).main
