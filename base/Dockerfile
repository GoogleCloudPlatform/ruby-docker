FROM google/debian:wheezy

RUN apt-get update
RUN apt-get install --no-install-recommends -y -q curl libyaml-dev libreadline6-dev libncurses5-dev libssl-dev libgdbm-dev libqdbm-dev libffi-dev libz-dev libgmp-dev build-essential autoconf ca-certificates systemtap
RUN mkdir -p /usr/src && curl http://ftp.ruby-lang.org/pub/ruby/2.1/ruby-2.1.2.tar.bz2 | tar -C /usr/src -xj
RUN cd /usr/src/ruby-2.1.2 && autoconf && ./configure --prefix=/usr --disable-install-doc && make && make install && make clean
RUN gem install -q --no-rdoc --no-ri bundler --version 1.6.3
