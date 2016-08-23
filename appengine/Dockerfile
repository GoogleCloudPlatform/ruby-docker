# Base Dockerfile for an App Engine Ruby runtime.
# Dockerfiles for App Engine Ruby apps should inherit FROM this image.

# The base image installs a version of Debian.
FROM gcr.io/google_appengine/base

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
        systemtap && \
    apt-get clean && \
    rm /var/lib/apt/lists/*_*

# Install node
RUN mkdir /nodejs && curl https://nodejs.org/dist/v6.4.0/node-v6.4.0-linux-x64.tar.gz | tar xvzf - -C /nodejs --strip-components=1
ENV PATH /nodejs/bin:$PATH

# Install rbenv
ENV RBENV_ROOT /rbenv
RUN git clone https://github.com/sstephenson/rbenv.git /rbenv && \
    git clone https://github.com/sstephenson/ruby-build.git /rbenv/plugins/ruby-build
ENV PATH /rbenv/shims:/rbenv/bin:$PATH

# Preinstall ruby runtimes.
# The LAST version in the list is set as the default.
ENV PREINSTALLED_RUBY_VERSIONS 2.1.8 2.2.4 2.3.0
ENV RUBY_CONFIGURE_OPTS --disable-install-doc
RUN for V in $PREINSTALLED_RUBY_VERSIONS; do \
    rbenv install -v $V; \
    rbenv rehash; \
    rbenv global $V; \
    done

# Preinstall bundler gem
ENV BUNDLER_VERSION 1.12.5
RUN for V in $PREINSTALLED_RUBY_VERSIONS; do \
    RBENV_VERSION=$V gem install -q --no-rdoc --no-ri bundler --version $BUNDLER_VERSION; \
    rbenv rehash; \
    done
# Tell nokogiri >=1.6 to install using system libraries, for faster builds
RUN bundle config build.nokogiri --use-system-libraries
ENV NOKOGIRI_USE_SYSTEM_LIBRARIES 1

# Temporarily replace ImageMagick policy file with one that fixes
# CVE-2016-3714 and others.
RUN mkdir -p /etc/ImageMagick-6 && rm -f /etc/ImageMagick-6/policy.xml
COPY files/policy.xml /etc/ImageMagick-6/

# Common configuration for any ENTRYPOINT
WORKDIR /app
EXPOSE 8080
ENV PORT 8080
CMD []

# Default ENTRYPOINT
ENV RACK_ENV deployment
ENTRYPOINT bundle exec rackup -p $PORT config.ru -E $RACK_ENV
