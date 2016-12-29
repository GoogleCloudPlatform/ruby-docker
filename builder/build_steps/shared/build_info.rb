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

  class ErbSandbox
    def run template, data={}
      data.each do |k, v|
        instance_variable_set("@#{k}", v)
      end
      ::ERB.new(template).result(binding)
    end
  end

  attr_reader :testing
  attr_reader :builder_dir
  attr_reader :workspace_dir
  attr_reader :rbenv_dir
  attr_reader :app_yaml
  attr_reader :runtime_config
  attr_reader :ruby_version

  def initialize args
    @testing = false
    @builder_dir = ::File.absolute_path(::File.dirname __FILE__)
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
    end.parse! args
    @app_yaml = ::Psych.load_file "#{@workspace_dir}/app.yaml" rescue {}
    @runtime_config = @app_yaml["runtime_config"] || {}
    @ruby_version = ::File.read("#{@workspace_dir}/.ruby-version") rescue ''
    @ruby_version.strip!
    ::Dir.chdir workspace_dir
  end

  def write_file filename, data={}
    template = ::File.read "#{builder_dir}/templates/#{filename}.erb"
    content = ErbSandbox.new.run template, data
    ::File.open "#{workspace_dir}/#{filename}", "w" do |file|
      file.write content
    end
    log "Wrote #{filename}"
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
end
