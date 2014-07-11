FROM google/ruby

# TODO(yugui) Replace unicorn with the dependency gem
RUN gem install -q --no-rdoc --no-ri unicorn --version 4.8.3
ADD unicorn.conf /app/

EXPOSE 8080

WORKDIR /app
ONBUILD ADD Gemfile /app/Gemfile
ONBUILD ADD Gemfile.lock /app/Gemfile.lock
ONBUILD RUN ["/usr/bin/bundle", "install"]
ONBUILD ADD . /app
ENTRYPOINT ["/usr/bin/bundle", "exec", "unicorn", "-c", "unicorn.conf", "config.ru"]
