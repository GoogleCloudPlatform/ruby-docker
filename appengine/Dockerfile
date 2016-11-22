# Base Dockerfile for an App Engine Ruby runtime.
# Dockerfiles for App Engine Ruby apps should inherit FROM this image.

# The base image installs a version of Debian.
FROM gcr.io/google_appengine/debian8

# Install dependencies for Ruby
# Also installs dependencies for the following common gems:
#
# gems      dependencies
# ------------------------------------------------------------------
# curb      libcurl3, libcurl3-gnutls, libcurl4-openssl-dev
# pg        libpq-dev
# rmagick   libmagickwand-dev
# nokogiri  libxml2-dev, libxslt-dev
# sqlite3   libsqlite3-dev
# mysql2    libmysqlclient-dev

RUN apt-get update -y && \
    apt-get install -y -q --no-install-recommends \
        apt-utils \
        autoconf \
        build-essential \
        ca-certificates \
        curl \
        git \
        libffi-dev \
        libgdbm-dev \
        libgmp-dev \
        libncurses5-dev \
        libqdbm-dev \
        libreadline6-dev \
        libssl-dev \
        libyaml-dev \
        libz-dev \
        libxml2-dev \
        libxslt-dev \
        libsqlite3-dev \
        libmysqlclient-dev \
        libpq-dev \
        libcurl3 \
        libcurl3-gnutls \
        libcurl4-openssl-dev \
        libmagickwand-dev \
        systemtap

# Install node
RUN mkdir /nodejs && curl https://nodejs.org/dist/v6.9.1/node-v6.9.1-linux-x64.tar.gz | tar xvzf - -C /nodejs --strip-components=1
ENV PATH /nodejs/bin:$PATH

# Install rbenv
ENV RBENV_ROOT /rbenv
RUN git clone https://github.com/sstephenson/rbenv.git /rbenv && \
    git clone https://github.com/sstephenson/ruby-build.git /rbenv/plugins/ruby-build
ENV PATH /rbenv/shims:/rbenv/bin:$PATH

# Preinstalled default ruby version.
ENV DEFAULT_RUBY_VERSION 2.3.1
ENV BUNDLER_VERSION 1.13.6

# Set ruby runtime distribution
ARG RUNTIME_DISTRIBUTION="ruby-runtime-jessie"

# Install the default ruby binary and bundler.
RUN (echo "deb http://packages.cloud.google.com/apt ${RUNTIME_DISTRIBUTION} main" \
      | tee /etc/apt/sources.list.d/ruby-runtime-jessie.list) && \
    (curl https://packages.cloud.google.com/apt/doc/apt-key.gpg \
      | apt-key add -) && \
    apt-get update -y && \
    apt-get install -y -q gcp-ruby-$DEFAULT_RUBY_VERSION && \
    rbenv rehash && \
    rbenv global $DEFAULT_RUBY_VERSION && \
    gem install -q --no-rdoc --no-ri bundler --version $BUNDLER_VERSION && \
    rbenv rehash

# Tell nokogiri >=1.6 to install using system libraries, for faster builds
RUN bundle config build.nokogiri --use-system-libraries
ENV NOKOGIRI_USE_SYSTEM_LIBRARIES 1

# Temporarily replace ImageMagick policy file with one that fixes
# CVE-2016-3714 and others.
RUN mkdir -p /etc/ImageMagick-6 && rm -f /etc/ImageMagick-6/policy.xml
COPY files/policy.xml /etc/ImageMagick-6/

# Clean up apt
RUN apt-get clean && rm -f /var/lib/apt/lists/*_*

# Common configuration for any ENTRYPOINT
WORKDIR /app
EXPOSE 8080
ENV PORT 8080
CMD []

# Default ENTRYPOINT
ENV RACK_ENV=production \
    RAILS_ENV=production \
    APP_ENV=production \
    RAILS_SERVE_STATIC_FILES=true
ENTRYPOINT bundle exec rackup -p $PORT config.ru -E $RACK_ENV
