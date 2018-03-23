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

ARG base_image
ARG build_tools_image
ARG prebuilt_ruby_image_base
ARG prebuilt_ruby_image_tag
ARG prebuilt_ruby_versions
ARG default_ruby_version

# Install the Dockerfile generation script and template.
COPY app/ /app/

ENV RUBY_BASE_IMAGE=${base_image} \
    RUBY_BUILD_TOOLS_IMAGE=${build_tools_image} \
    PREBUILT_RUBY_IMAGE_BASE=${prebuilt_ruby_image_base} \
    PREBUILT_RUBY_IMAGE_TAG=${prebuilt_ruby_image_tag} \
    PREBUILT_RUBY_VERSIONS=${prebuilt_ruby_versions} \
    DEFAULT_RUBY_VERSION=${default_ruby_version}


# The entry point runs the generation script.
ENTRYPOINT ["/app/generate_dockerfile.sh"]
