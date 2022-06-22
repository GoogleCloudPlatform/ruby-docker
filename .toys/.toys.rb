# Copyright 2022 Google LLC
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

mixin "runtime-params" do
  on_include do
    File.readlines("#{context_directory}/runtime-config.env").each do |line|
      if line =~ /^([A-Z][A-Z0-9_]*)=(.*)$/
        match = Regexp.last_match
        name_str = match[1]
        name_sym = name_str.downcase.to_sym
        value = match[2]
        static name_sym, value
        ENV[name_str] = value
      end
    end
    all_versions = []
    default_version = nil
    File.readlines("#{context_directory}/ruby-pipeline/ruby-latest.yaml").each do |line|
      all_versions << Regexp.last_match[1] if line =~ /([\d\.]+)=gcr\.io/
      default_version = Regexp.last_match[1] if line =~ /--default-ruby-version=([\d\.]+)/
    end
    all_versions = all_versions.join ","
    static :all_prebuilt_ruby_versions, all_versions
    static :default_ruby_version, default_version
    ENV["ALL_PREBUILT_RUBY_VERSIONS"] = all_versions
    ENV["DEFAULT_RUBY_VERSION"] = default_version
  end
end

tool "build" do
  desc "Build all images locally"

  flag :project, "--project=PROJECT", default: "gcp-runtimes"
  flag :os_name, "--os-name=NAME", default: "ubuntu20"
  flag :use_local_prebuilt

  include :exec, e: true
  include "runtime-params"

  def run
    cmd = [
      "build", "os-image",
      "--os-name", os_name,
      "--bundler2-version", bundler2_version,
      "--nodejs-version", nodejs_version,
      "--ssl10-version", ssl10_version
    ]
    exec_tool cmd
    exec_tool cmd + ["--use-ssl10-dev"]
    if use_local_prebuilt
      cmd = ["build", "prebuilt", "--os-name", os_name] + primary_ruby_versions.split(",")
      exec_tool cmd
    end
    cmd = [
      "build", "basic",
      "--use-prebuilt-binary",
      "--os-name", os_name,
      "--ruby-version", basic_ruby_version,
      "--bundler1-version", bundler1_version,
      "--bundler2-version", bundler2_version
    ]
    cmd << "--use-local-prebuilt" if use_local_prebuilt
    exec_tool cmd
    exec_tool [
      "build", "build-tools",
      "--gcloud-version", gcloud_version,
      "--bundler1-version", bundler1_version,
      "--bundler2-version", bundler2_version
    ]
    cmd = [
      "build", "generate-dockerfile",
      "--os-name", os_name,
      "--default-ruby-version", default_ruby_version,
      "--bundler1-version", bundler1_version,
      "--bundler2-version", bundler2_version
    ]
    if use_local_prebuilt
      primary_ruby_versions.split(",").each do |version|
        cmd << "--prebuilt-image=#{version}=ruby-prebuilt-#{version}:latest"
      end
    else
      all_prebuilt_ruby_versions.split(",").each do |version|
        cmd << "--prebuilt-image=#{version}=gcr.io/#{project}/ruby/#{os_name}/prebuilt/ruby-#{version}:latest"
      end
    end
    exec_tool cmd
    exec_tool ["build", "app-engine-exec-wrapper"]
    exec_tool ["build", "app-engine-exec-harness"]
  end
end

tool "test" do
  desc "Run all tests"

  flag :project, "--project=PROJECT", default: "gcp-runtimes"
  flag :os_name, "--os-name=NAME", default: "ubuntu20"
  flag :use_local_prebuilt
  flag :faster
  remaining_args :tests

  include :exec, e: true
  include "runtime-params"

  def run
    env = {
      "PREBUILT_RUBY_IMAGE_TAG" => "latest",
      "PREBUILT_RUBY_VERSIONS" => all_prebuilt_ruby_versions,
      "PRIMARY_RUBY_VERSIONS" => primary_ruby_versions,
      "BUNDLER1_VERSION" => bundler1_version,
      "BUNDLER2_VERSION" => bundler2_version,
      "TESTING_OS_NAME" => os_name
    }
    env["USE_LOCAL_PREBUILT"] = "true" if use_local_prebuilt
    env["FASTER_TESTS"] = "true" if faster
    env["PREBUILT_RUBY_IMAGE_BASE"] = use_local_prebuilt ? "ruby-prebuilt-" : "gcr.io/#{project}/ruby/#{os_name}/prebuilt/ruby-"
    cmd = ["_test"] + tests
    exec_tool cmd, env: env
  end
end

expand :minitest, name: "_test", files: ["test/test*.rb"]
