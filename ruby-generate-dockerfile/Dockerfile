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

# Use the Ruby base image to get Ruby and its dependencies.
FROM ruby-base

ARG base_image=""
ARG build_tools_image=""
ARG prebuilt_ruby_images=""
ARG default_ruby_version=""
ARG bundler1_version=""
ARG bundler2_version=""

ENV DEFAULT_RUBY_BASE_IMAGE=${base_image} \
    DEFAULT_RUBY_BUILD_TOOLS_IMAGE=${build_tools_image} \
    DEFAULT_PREBUILT_RUBY_IMAGES=${prebuilt_ruby_images} \
    DEFAULT_RUBY_VERSION=${default_ruby_version} \
    PROVIDED_BUNDLER1_VERSION=${bundler1_version} \
    PROVIDED_BUNDLER2_VERSION=${bundler2_version}

# Install the Dockerfile generation script and template.
COPY app/ /app/

# The entry point runs the generation script.
ENTRYPOINT ["/app/generate_dockerfile.sh"]
