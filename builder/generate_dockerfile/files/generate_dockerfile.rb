#!/rbenv/shims/ruby

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

require "erb"
require "optparse"

require_relative "app_config.rb"

class GenerateDockerfile
  DEFAULT_WORKSPACE_DIR = "/workspace"
  DEFAULT_BASE_IMAGE = "gcr.io/google-appengine/ruby"
  DEFAULT_BUILD_TOOLS_IMAGE = "gcr.io/gcp-runtimes/ruby/build-tools"
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
    @base_image = DEFAULT_BASE_IMAGE
    @build_tools_image = DEFAULT_BUILD_TOOLS_IMAGE
    @testing = false
    @access_token_file = false
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
      opts.on "--capture-access-token" do
        @access_token_file = nil
      end
    end.parse! args
    ::Dir.chdir @workspace_dir
    begin
      @app_config = AppConfig.new @workspace_dir
    rescue AppConfig::Error => ex
      ::STDERR.puts ex.message
      exit 1
    end
    @timestamp = ::Time.now.utc.strftime "%Y-%m-%d %H:%M:%S UTC"
  end

  def main
    setup_access_token if @access_token_file.nil?
    write_dockerfile
    write_dockerignore
    if @testing
      system "chmod -R a+w #{@app_config.workspace_dir}"
    end
  end

  # Should go away after internal issue b/63630627 is fixed.
  def setup_access_token
    cmd = 'curl -s -H "Metadata-Flavor: Google"' \
      ' http://metadata.google.internal/computeMetadata/v1/instance/' \
      'service-accounts/default/token'
    json = `#{cmd}`
    unless json.start_with? '{"'
      ::STDERR.puts "Unable to auth because metadata query failed."
      exit 1
    end
    token_data = ::JSON.parse json
    access_token = token_data["access_token"]
    unless access_token
      ::STDERR.puts "Unable to auth because credentials are missing."
      exit 1
    end

    10.times do
      @access_token_file = "google_access_token_#{"%08d" % rand(100000000)}"
      access_token_path = "#{@app_config.workspace_dir}/#{@access_token_file}"
      unless ::File.exist? access_token_path
        ::File.open access_token_path, "w" do |file|
          file.write access_token
        end
        return
      end
    end
    ::STDERR.puts "Unable to find a free path for the access token"
    exit 1
  end

  def write_dockerfile
    b = binding
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

  def escape_quoted str
    str.gsub("\\", "\\\\").gsub("\"", "\\\"").gsub("\n", "\\n")
  end
end

GenerateDockerfile.new(::ARGV).main
