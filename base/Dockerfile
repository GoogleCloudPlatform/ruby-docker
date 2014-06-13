FROM google/debian:wheezy

RUN apt-get update
RUN apt-get install --no-install-recommends -y -q wget libyaml-dev libreadline6-dev libncurses5-dev libssl-dev libgdbm-dev libqdbm-dev libffi-dev libz-dev libgmp-dev clang make autoconf bzip2 ca-certificates systemtap
RUN wget -q http://ftp.ruby-lang.org/pub/ruby/2.1/ruby-2.1.2.tar.bz2 && mkdir -p /usr/src && mv ruby-2.1.2.tar.bz2 /usr/src && tar -C /usr/src -xjf /usr/src/ruby-2.1.2.tar.bz2 && rm /usr/src/ruby-2.1.2.tar.bz2
RUN cd /usr/src/ruby-2.1.2 && autoconf && ./configure --prefix=/usr --disable-install-doc && make && make install && make clean
RUN gem install -q --no-rdoc --no-ri bundler --version 1.6.2
