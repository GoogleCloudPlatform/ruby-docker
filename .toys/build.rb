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

tool "os-image" do
  desc "Build local docker image the OS"

  flag :os_name, "--os-name=NAME", default: "ubuntu20"
  flag :use_ssl10_dev
  all_required do
    flag :bundler2_version, "--bundler2-version=VERSION"
    flag :nodejs_version, "--nodejs-version=VERSION"
    flag :ssl10_version, "--ssl10-version=VERSION"
  end

  include :exec, e: true

  def run
    sed_script = use_ssl10_dev ? "s|@@IF_SSL10_DEV@@||g" : "s|@@IF_SSL10_DEV@@|#|g"
    image_name = use_ssl10_dev ? "ruby-#{os_name}-ssl10" : "ruby-#{os_name}"
    exec ["sed", "-e", sed_script, "ruby-#{os_name}/Dockerfile.in"],
         out: [:file, "ruby-#{os_name}/Dockerfile"]
    exec ["docker", "build", "--pull", "--no-cache",
          "-t", "#{image_name}",
          "--build-arg", "bundler_version=#{bundler2_version}",
          "--build-arg", "nodejs_version=#{nodejs_version}",
          "--build-arg", "ssl10_version=#{ssl10_version}",
          "ruby-#{os_name}"]
  end
end

tool "prebuilt" do
  desc "Build prebuilt binary images"

  flag :os_name, "--os-name=NAME", default: "ubuntu20"
  remaining_args :ruby_versions

  include :exec, e: true

  def run
    if ruby_versions.empty?
      logger.error "At least one ruby version required"
      exit 1
    end
    ruby_versions.each do |version|
      os_image = version < "2.4" ? "ruby-#{os_name}-ssl10" : "ruby-#{os_name}"
      exec ["sed", "-e", "s|@@RUBY_OS_IMAGE@@|#{os_image}|g", "ruby-prebuilt/Dockerfile.in"],
           out: [:file, "ruby-prebuilt/Dockerfile"]
      exec ["docker", "build", "--no-cache",
            "-t", "ruby-prebuilt-#{version}",
            "--build-arg", "ruby_version=#{version}",
            "ruby-prebuilt"]
      end
  end
end

tool "basic" do
  desc "Build simple base image using the default ruby"

  flag :project, "--project=PROJECT", default: "gcp-runtimes"
  flag :os_name, "--os-name=NAME", default: "ubuntu20"
  flag :use_prebuilt_binary
  flag :use_local_prebuilt
  all_required do
    flag :ruby_version, "--ruby-version=VERSION"
    flag :bundler1_version, "--bundler1-version=VERSION"
    flag :bundler2_version, "--bundler2-version=VERSION"
  end

  include :exec, e: true

  def run
    image_type = use_prebuilt_binary ? "prebuilt" : "default"
    prebuilt_base = use_local_prebuilt ? "ruby-prebuilt-" : "gcr.io/#{project}/ruby/#{os_name}/prebuilt/ruby-"
    sed_script = "s|@@RUBY_OS_IMAGE@@|ruby-#{os_name}|g;"\
                 " s|@@PREBUILT_RUBY_IMAGE@@|#{prebuilt_base}#{ruby_version}|g"
    exec ["sed", "-e", sed_script, "ruby-base/Dockerfile-#{image_type}.in"],
         out: [:file, "ruby-base/Dockerfile"]
    exec ["docker", "build", "--no-cache",
          "-t", "ruby-base",
          "--build-arg", "ruby_version=#{ruby_version}",
          "--build-arg", "bundler1_version=#{bundler1_version}",
          "--build-arg", "bundler2_version=#{bundler2_version}",
          "ruby-base"]
  end
end

tool "build-tools" do
  desc "Build the build-tools image"

  all_required do
    flag :gcloud_version, "--gcloud-version=VERSION"
    flag :bundler1_version, "--bundler1-version=VERSION"
    flag :bundler2_version, "--bundler2-version=VERSION"
  end

  include :exec, e: true

  def run
    exec ["docker", "build", "--no-cache",
          "-t", "ruby-build-tools",
          "--build-arg", "gcloud_version=#{gcloud_version}",
          "--build-arg", "bundler1_version=#{bundler1_version}",
          "--build-arg", "bundler2_version=#{bundler2_version}",
          "ruby-build-tools"]
  end
end

tool "generate-dockerfile" do
  desc "Build the generate-dockerfile image"

  flag :os_name, "--os-name=NAME", default: "ubuntu20"
  flag :prebuilt_image, "--prebuilt-image=SPEC", handler: :push, default: []
  all_required do
    flag :default_ruby_version, "--default-ruby-version=VERSION"
    flag :bundler1_version, "--bundler1-version=VERSION"
    flag :bundler2_version, "--bundler2-version=VERSION"
  end

  include :exec, e: true

  def run
    prebuilt_ruby_images = prebuilt_image.join ","
    exec ["docker", "build", "--no-cache",
          "-t", "ruby-generate-dockerfile",
          "--build-arg", "base_image=ruby-#{os_name}",
          "--build-arg", "build_tools_image=ruby-build-tools",
          "--build-arg", "prebuilt_ruby_images=#{prebuilt_ruby_images}",
          "--build-arg", "default_ruby_version=#{default_ruby_version}",
          "--build-arg", "bundler1_version=#{bundler1_version}",
          "--build-arg", "bundler2_version=#{bundler2_version}",
          "ruby-generate-dockerfile"]
  end
end

tool "app-engine-exec-wrapper" do
  desc "Build the app-engine-exec wrapper"

  include :exec, e: true

  def run
    exec ["docker", "build", "--no-cache",
          "-t", "app-engine-exec-wrapper",
          "app-engine-exec-wrapper"]
  end
end

tool "app-engine-exec-harness" do
  desc "Build the fake test harmess image for app-engine-exec wrapper"

  include :exec, e: true

  def run
    exec ["docker", "build", "--no-cache",
          "-t", "app-engine-exec-harness",
          "test/app_engine_exec_wrapper/harness"]
  end
end
