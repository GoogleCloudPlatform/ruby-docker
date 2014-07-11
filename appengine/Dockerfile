FROM google/ruby

# TODO(yugui) Replace puma with the dependency gem
RUN gem install -q --no-rdoc --no-ri puma --version 2.8.2

EXPOSE 8080
CMD []
ENV APPSERVER puma
ENTRYPOINT /usr/bin/bundle exec rackup -p 8080 /app/config.ru -s $APPSERVER

WORKDIR /app
ONBUILD ADD Gemfile /app/Gemfile
ONBUILD ADD Gemfile.lock /app/Gemfile.lock
ONBUILD RUN ["/usr/bin/bundle", "install"]
ONBUILD ADD . /app
