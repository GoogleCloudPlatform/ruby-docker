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

require "erb"
require "optparse"
require "psych"

class BuildInfo
  DEFAULT_WORKSPACE_DIR = "/workspace"
  DEFAULT_RBENV_DIR = "/rbenv"
  DEFAULT_APP_YAML_PATH = "app.yaml"
  BUILDER_DIR = ::File.absolute_path(::File.dirname __FILE__)
  DEFAULT_ENTRYPOINT = "bundle exec rackup -p $PORT"

  class ErbSandbox
    def run template, data={}
      data.each do |k, v|
        instance_variable_set("@#{k}", v)
      end
      ::ERB.new(template).result(binding)
    end
  end

  attr_reader :testing
  attr_reader :workspace_dir
  attr_reader :rbenv_dir
  attr_reader :app_yaml_path
  attr_reader :env_variables
  attr_reader :cloud_sql_instances
  attr_reader :build_scripts
  attr_reader :runtime_config
  attr_reader :raw_entrypoint
  attr_reader :entrypoint
  attr_reader :install_packages
  attr_reader :ruby_version

  def builder_dir; BUILDER_DIR; end

  def write_file filename, data={}
    template = ::File.read "#{builder_dir}/templates/#{filename}.erb"
    content = ErbSandbox.new.run template, data
    ::File.open "#{workspace_dir}/#{filename}", "w" do |file|
      file.write content
    end
    log "Wrote #{filename}"
  end

  def file_exists? filename
    ::File.exist? "#{workspace_dir}/#{filename}"
  end

  def log s
    ::STDERR.puts s
  end

  def check_cmd c
    system c
  end

  def ensure_cmd c
    unless system c
      abort "FAILED COMMAND: #{c}"
    end
  end

  def banner name, description=""
    log "**********************************************************************"
    log "** BUILD STEP: #{name}"
    log description.split("\n").map{ |s| "** #{s}" }.join("\n")
    log "**********************************************************************"
  end

  def cleanup_file_perms
    if testing
      check_cmd "chmod -R a+w #{workspace_dir}"
      log "Made everything writeable for test cleanup"
    end
  end

  def initialize args, &config_optparser
    init_args args, &config_optparser
    init_app_config
    init_build_scripts
    init_entrypoint
    init_packages
    init_ruby_version
    ::Dir.chdir workspace_dir
  end

  private

  def init_args args
    @testing = false
    @enable_packages = false
    @workspace_dir = DEFAULT_WORKSPACE_DIR
    @rbenv_dir = DEFAULT_RBENV_DIR
    ::OptionParser.new do |opts|
      opts.on "-t" do
        @testing = true
      end
      opts.on "--workspace-dir=PATH" do |path|
        @workspace_dir = ::File.absolute_path path
      end
      opts.on "--rbenv-dir=PATH" do |path|
        @rbenv_dir = ::File.absolute_path path
      end
      opts.on "--enable-packages" do
        @enable_packages = true
      end
      yield opts if block_given?
    end.parse! args
  end

  def init_app_config
    @app_yaml_path = ::ENV["GAE_APPLICATION_YAML_PATH"] || DEFAULT_APP_YAML_PATH
    @app_config =
      ::Psych.load_file("#{@workspace_dir}/#{@app_yaml_path}") rescue {}
    @env_variables = @app_config["env_variables"] || {}
    @runtime_config = @app_config["runtime_config"] || {}
    @beta_settings = @app_config["beta_settings"] || {}
    @lifecycle = @app_config["lifecycle"] || {}
    @cloud_sql_instances = Array(@beta_settings["cloud_sql_instances"])
  end

  def init_build_scripts
    if ::File.directory?("#{@workspace_dir}/app/assets") &&
        ::File.file?("#{@workspace_dir}/config/application.rb")
      default_build_scripts = ["bundle exec rake assets:precompile || true"]
    else
      default_build_scripts = []
    end
    raw_build_scripts = @lifecycle["build"] || @runtime_config["build"]
    @build_scripts = case raw_build_scripts
      when nil then default_build_scripts
      when '' then []
      when ::String then [raw_build_scripts]
      when ::Array then raw_build_scripts
      else []
    end
  end

  def init_entrypoint
    @raw_entrypoint =
        @runtime_config["entrypoint"] ||
        @app_config["entrypoint"] ||
        DEFAULT_ENTRYPOINT
    @entrypoint = decorate_entrypoint @raw_entrypoint
  end

  # Prepare entrypoint for rendering into the dockerfile.
  # If the provided entrypoint is an array, render it in exec format.
  # If the provided entrypoint is a string, we have to render it in shell
  # format. Now, we'd like to prepend "exec" so signals get caught properly.
  # However, there are some edge cases that we omit for safety.
  def decorate_entrypoint entrypoint
    return JSON.generate entrypoint if entrypoint.is_a? Array
    return entrypoint if entrypoint.start_with? "exec "
    return entrypoint if entrypoint =~ /;|&&|\|/
    "exec #{entrypoint}"
  end

  def init_packages
    @install_packages = []
    if @enable_packages
      @install_packages = Array(
        @runtime_config["packages"] || @app_config["packages"]
      )
    end
  end

  def init_ruby_version
    @ruby_version = ::File.read("#{@workspace_dir}/.ruby-version") rescue ''
    @ruby_version.strip!
  end
end
