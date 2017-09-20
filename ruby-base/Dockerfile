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


# This is the base Dockerfile for an App Engine Ruby runtime.
# Dockerfiles for App Engine Ruby apps should inherit FROM this image.

# The base image installs a version of Debian.
FROM gcr.io/google-appengine/debian8

# Install dependencies for Ruby
# Also installs dependencies for the following common gems:
#
# gems             dependencies
# ------------------------------------------------------------------
# curb             libcurl3, libcurl3-gnutls, libcurl4-openssl-dev
# pg               libpq-dev
# rmagick          imagemagick, libmagickwand-dev
# nokogiri         libxml2-dev, libxslt-dev
# sqlite3          libsqlite3-dev
# mysql2           libmysqlclient-dev
# paperclip        file
# charlock_holmes  libicu-dev
# rugged           libgit2-dev

RUN apt-get update -y && \
    apt-get install -y -q --no-install-recommends \
        apt-utils \
        autoconf \
        build-essential \
        ca-certificates \
        cmake \
        curl \
        git \
        file \
        imagemagick \
        libcurl3 \
        libcurl3-gnutls \
        libcurl4-openssl-dev \
        libffi-dev \
        libgdbm-dev \
        libgit2-dev \
        libgmp-dev \
        libicu-dev \
        libmagickwand-dev \
        libmysqlclient-dev \
        libncurses5-dev \
        libpq-dev \
        libqdbm-dev \
        libreadline6-dev \
        libsqlite3-dev \
        libssl-dev \
        libxml2-dev \
        libxslt-dev \
        libyaml-dev \
        libz-dev \
        systemtap

# Install node
RUN mkdir /nodejs && curl -s https://nodejs.org/dist/v6.11.3/node-v6.11.3-linux-x64.tar.gz | tar xvzf - -C /nodejs --strip-components=1
ENV PATH /nodejs/bin:$PATH

# Install rbenv
ENV RBENV_ROOT /rbenv
RUN git clone https://github.com/sstephenson/rbenv.git $RBENV_ROOT && \
    git clone https://github.com/sstephenson/ruby-build.git $RBENV_ROOT/plugins/ruby-build
ENV PATH $RBENV_ROOT/shims:$RBENV_ROOT/bin:$PATH

# Preinstalled default ruby version.
ENV DEFAULT_RUBY_VERSION 2.3.5
ENV BUNDLER_VERSION 1.15.4

# Set ruby runtime distribution
ARG RUNTIME_DISTRIBUTION="ruby-runtime-jessie"

# Default gem installation options
COPY .gemrc /root/.gemrc

# Install the default ruby binary and bundler.
RUN (echo "deb http://packages.cloud.google.com/apt ${RUNTIME_DISTRIBUTION} main" \
      | tee /etc/apt/sources.list.d/ruby-runtime-jessie.list) && \
    (curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg \
      | apt-key add -) && \
    apt-get update -y && \
    apt-get install -y -q gcp-ruby-$DEFAULT_RUBY_VERSION && \
    rbenv rehash && \
    rbenv global $DEFAULT_RUBY_VERSION && \
    gem install bundler --version $BUNDLER_VERSION && \
    rbenv rehash

# Tell nokogiri >=1.6 to install using system libraries, for faster builds
RUN bundle config build.nokogiri --use-system-libraries
ENV NOKOGIRI_USE_SYSTEM_LIBRARIES 1

# Temporarily replace ImageMagick policy file with one that fixes
# CVE-2016-3714 and others.
RUN mkdir -p /etc/ImageMagick-6 && rm -f /etc/ImageMagick-6/policy.xml
COPY policy.xml /etc/ImageMagick-6/

# Clean up apt
RUN apt-get clean && rm -f /var/lib/apt/lists/*_*

# Common environment variables for framework configuration
ENV RACK_ENV=production \
    RAILS_ENV=production \
    APP_ENV=production \
    RAILS_SERVE_STATIC_FILES=true \
    RAILS_LOG_TO_STDOUT=true

# Initialize entrypoint
WORKDIR /app
EXPOSE 8080
ENV PORT=8080
ENTRYPOINT []
CMD []
