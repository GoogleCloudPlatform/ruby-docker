# Base Dockerfile for an App Engine Ruby runtime

FROM gcr.io/google_appengine/base

# Install dependencies
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
        systemtap && \
    apt-get clean && \
    rm /var/lib/apt/lists/*_*

# Install the latest MRI and bundler.
RUN mkdir -p /usr/src && \
    curl http://cache.ruby-lang.org/pub/ruby/2.2/ruby-2.2.3.tar.bz2 | \
        tar -C /usr/src -xj
RUN cd /usr/src/ruby-2.2.3 && \
    autoconf && \
    ./configure --prefix=/usr --disable-install-doc && \
    make && make install && make clean
RUN /usr/bin/gem install -q --no-rdoc --no-ri bundler --version 1.10.6

# Install application-specified gem dependencies
WORKDIR /app
ONBUILD ADD Gemfile /app/Gemfile
ONBUILD ADD Gemfile.lock /app/Gemfile.lock
ONBUILD RUN /usr/bin/bundle install --deployment

# Default settings.
ENV RACK_HANDLER webrick
ENV RACK_ENV production

# Start the server on port 8080.
ONBUILD ADD . /app
EXPOSE 8080
CMD []
ENTRYPOINT /usr/bin/bundle exec rackup \
    -p 8080 /app/config.ru -s $RACK_HANDLER -E $RACK_ENV
