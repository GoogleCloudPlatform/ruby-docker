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

RUNTIME_PROJECT="gcp-runtimes"
BUNDLER_VERSION="1.16.1"
DEFAULT_RUBY_VERSION="2.5.0"
NODEJS_VERSION="8.10.0"
GCLOUD_VERSION="194.0.0"
OS_NAME="ubuntu16"

LOCAL_PREBUILT_RUBY_VERSIONS=["2.4.3", "2.5.0"]
LOCAL_PREBUILT_RUBY_IMAGE_BASE="ruby-prebuilt-"
LOCAL_PREBUILT_RUBY_IMAGE_TAG="latest"
RELEASED_PREBUILT_RUBY_VERSIONS=[]
RELEASED_PREBUILT_RUBY_IMAGE_BASE="gcr.io/#{RUNTIME_PROJECT}/ruby/#{OS_NAME}/prebuilt/ruby-"
RELEASED_PREBUILT_RUBY_IMAGE_TAG="staging"

USE_LOCAL_PREBUILT = ::ENV["USE_LOCAL_PREBUILT"] == "true"
if USE_LOCAL_PREBUILT
  PREBUILT_RUBY_VERSIONS=LOCAL_PREBUILT_RUBY_VERSIONS
  PREBUILT_RUBY_IMAGE_BASE=LOCAL_PREBUILT_RUBY_IMAGE_BASE
  PREBUILT_RUBY_IMAGE_TAG=LOCAL_PREBUILT_RUBY_IMAGE_TAG
else
  PREBUILT_RUBY_VERSIONS=RELEASED_PREBUILT_RUBY_VERSIONS
  PREBUILT_RUBY_IMAGE_BASE=RELEASED_PREBUILT_RUBY_IMAGE_BASE
  PREBUILT_RUBY_IMAGE_TAG=RELEASED_PREBUILT_RUBY_IMAGE_TAG
end
::ENV["PREBUILT_RUBY_VERSIONS"] = PREBUILT_RUBY_VERSIONS.join(",")
::ENV["PREBUILT_RUBY_IMAGE_BASE"] = PREBUILT_RUBY_IMAGE_BASE
::ENV["PREBUILT_RUBY_IMAGE_TAG"] = PREBUILT_RUBY_IMAGE_TAG

::Dir.chdir __dir__

require "rake/testtask"

desc "Build local docker image for ubuntu16 image"
task "build:ubuntu16" do |t, args|
  sh "docker build --pull --no-cache -t ruby-ubuntu16" \
    " --build-arg bundler_version=#{BUNDLER_VERSION}" \
    " --build-arg nodejs_version=#{NODEJS_VERSION}" \
    " ruby-ubuntu16"
end

desc "Build local docker image for current OS image"
task "build:osimage" => "build:#{OS_NAME}"

desc "Build local prebuilt ruby images"
task "build:prebuilt" do |t, args|
  sh "sed -e 's|@@RUBY_OS_IMAGE@@|ruby-#{OS_NAME}|g'" \
    " ruby-prebuilt/Dockerfile.in > ruby-prebuilt/Dockerfile"
  LOCAL_PREBUILT_RUBY_VERSIONS.each do |ruby_version|
    image_name = "#{LOCAL_PREBUILT_RUBY_IMAGE_BASE}#{ruby_version}:#{LOCAL_PREBUILT_RUBY_IMAGE_TAG}"
    sh "docker build --no-cache -t #{image_name}" \
      " --build-arg ruby_version=#{ruby_version}" \
      " ruby-prebuilt"
  end
end

desc "Build local docker image for base image"
task "build:base" do |t, args|
  if PREBUILT_RUBY_VERSIONS.include? DEFAULT_RUBY_VERSION
    sh "sed -e 's|@@RUBY_OS_IMAGE@@|ruby-#{OS_NAME}|g; s|@@PREBUILT_RUBY_IMAGE@@|" \
      "#{PREBUILT_RUBY_IMAGE_BASE}#{DEFAULT_RUBY_VERSION}:#{PREBUILT_RUBY_IMAGE_TAG}|g'" \
      " ruby-base/Dockerfile-prebuilt.in > ruby-base/Dockerfile"
  else
    sh "sed -e 's|@@RUBY_OS_IMAGE@@|ruby-#{OS_NAME}|g'" \
      " ruby-base/Dockerfile-default.in > ruby-base/Dockerfile"
  end
  sh "docker build --no-cache -t ruby-base" \
    " --build-arg ruby_version=#{DEFAULT_RUBY_VERSION}" \
    " ruby-base"
end

desc "Build local docker image for build-tools image"
task "build:build-tools" do |t, args|
  sh "docker build --no-cache -t ruby-build-tools" \
    " --build-arg gcloud_version=#{GCLOUD_VERSION}" \
    " ruby-build-tools"
end

desc "Build local docker image for generate-dockerfile image"
task "build:generate-dockerfile" do |t, args|
  sh "docker build --no-cache -t ruby-generate-dockerfile" \
    " --build-arg base_image=ruby-#{OS_NAME}" \
    " --build-arg build_tools_image=ruby-build-tools" \
    " --build-arg prebuilt_ruby_image_base=#{PREBUILT_RUBY_IMAGE_BASE}" \
    " --build-arg prebuilt_ruby_image_tag=#{PREBUILT_RUBY_IMAGE_TAG}" \
    " --build-arg prebuilt_ruby_versions=#{PREBUILT_RUBY_VERSIONS.join(',')}" \
    " --build-arg default_ruby_version=#{DEFAULT_RUBY_VERSION}" \
    " ruby-generate-dockerfile"
end

desc "Build local docker image for app engine exec wrapper"
task "build:app-engine-exec-wrapper" do |t, args|
  sh "docker build --no-cache -t app-engine-exec-wrapper app-engine-exec-wrapper"
end

desc "Build fake test harness image for app engine exec wrapper"
task "build:app-engine-exec-harness" do |t, args|
  sh "docker build --no-cache -t app-engine-exec-harness test/app_engine_exec_wrapper/harness"
end

desc "Build all local docker images"
task "build" => [
  "build:osimage",
  "build:prebuilt",
  "build:base",
  "build:build-tools",
  "build:generate-dockerfile",
  "build:app-engine-exec-wrapper",
  "build:app-engine-exec-harness"
]

desc "Run all tests without doing a build"
Rake::TestTask.new "test:only" do |t|
  t.test_files = FileList['test/test_*.rb']
end

desc "Run base image tests without doing a build"
Rake::TestTask.new "test:base:only" do |t|
  t.test_files = FileList['test/test_base_*.rb']
end

desc "Run app-engine-exec-wrapper tests without doing a build"
Rake::TestTask.new "test:exec:only" do |t|
  t.test_files = FileList['test/test_app_engine_exec_wrapper.rb']
end

desc "Run subsequent tests faster by omitting some slow low-priority ones"
task "faster" do
  ::ENV["FASTER_TESTS"] = "true"
end

desc "Build local docker images and run all tests"
task "test" => ["build", "test:only"]

desc "Build local docker images and run base image tests"
task "test:base" => ["build", "test:base:only"]

task :default => "test"
