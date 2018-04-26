# Copyright 2018 Google LLC
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
#
# Installs dependencies for the following common gems:
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


FROM gcr.io/gcp-runtimes/ubuntu_16_0_4

ARG bundler_version
ARG nodejs_version

ENV RBENV_ROOT=/opt/rbenv \
    DEFAULT_BUNDLER_VERSION=${bundler_version}

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update -y \
    && apt-get install -y -q --no-install-recommends \
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
        libgmp-dev \
        libicu-dev \
        libjemalloc-dev \
        libjemalloc1 \
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
        systemtap \
        tzdata \
    && apt-get install -y -q --no-install-recommends libgit2-dev \
    && apt-get clean \
    && rm -f /var/lib/apt/lists/*_* \
    && mkdir -p /opt/nodejs \
    && rm -f /etc/ImageMagick-6/policy.xml \
    && git clone https://github.com/sstephenson/rbenv.git ${RBENV_ROOT} \
    && git clone https://github.com/sstephenson/ruby-build.git ${RBENV_ROOT}/plugins/ruby-build \
    && (curl -s https://nodejs.org/dist/v${nodejs_version}/node-v${nodejs_version}-linux-x64.tar.gz \
        | tar xzf - --directory=/opt/nodejs --strip-components=1) \
    && ln -s ${RBENV_ROOT} /rbenv \
    && ln -s /opt/nodejs /nodejs

COPY files /root

ENV PATH=/opt/nodejs/bin:${RBENV_ROOT}/shims:${RBENV_ROOT}/bin:${PATH} \
    RACK_ENV=production \
    RAILS_ENV=production \
    APP_ENV=production \
    RAILS_SERVE_STATIC_FILES=true \
    RAILS_LOG_TO_STDOUT=true \
    NOKOGIRI_USE_SYSTEM_LIBRARIES=1 \
    PORT=8080

# Initialize entrypoint
WORKDIR /app
EXPOSE 8080
ENTRYPOINT []
CMD []
