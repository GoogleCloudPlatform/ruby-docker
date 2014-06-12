FROM google/ruby

RUN gem install -q --no-rdoc --no-ri bundler --version 1.6.2
# TODO(yugui) Replace unicorn with the dependency gem
RUN gem install -q --no-rdoc --no-ri unicorn --version 4.8.3
ADD unicorn.conf /app/

EXPOSE 8080

WORKDIR /app
ONBUILD ADD Gemfile /app/Gemfile
ONBUILD RUN ["/usr/local/bin/bundle", "install"]
ONBUILD ADD . /app
ENTRYPOINT ["/usr/local/bin/bundle", "exec", "unicorn", "-c", "unicorn.conf", "config.ru"]
