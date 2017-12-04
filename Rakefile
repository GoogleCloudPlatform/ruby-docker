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

require "rake/testtask"

::Dir.chdir ::File.dirname __FILE__

desc "Build local docker image for base image"
task "build:base" do |t, args|
  sh "docker build --pull --no-cache -t ruby-base" \
    " --build-arg RUNTIME_DISTRIBUTION=ruby-runtime-jessie-unstable ruby-base"
end

desc "Build local docker image for build-tools image"
task "build:build-tools" do |t, args|
  sh "docker build --no-cache -t ruby-build-tools ruby-build-tools"
end

desc "Build local docker image for generate-dockerfile image"
task "build:generate-dockerfile" do |t, args|
  sh "docker build --no-cache -t ruby-generate-dockerfile ruby-generate-dockerfile"
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
task "build" => ["build:base", "build:build-tools", "build:generate-dockerfile",
                 "build:app-engine-exec-wrapper", "build:app-engine-exec-harness"]

desc "Run all tests without doing a build"
Rake::TestTask.new "test:only" do |t|
  t.test_files = FileList['test/tc_*.rb']
end

desc "Run base image tests without doing a build"
Rake::TestTask.new "test:base:only" do |t|
  t.test_files = FileList['test/tc_base_*.rb']
end

desc "Run app-engine-exec-wrapper tests without doing a build"
Rake::TestTask.new "test:exec:only" do |t|
  t.test_files = FileList['test/tc_app_engine_exec_wrapper.rb']
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
