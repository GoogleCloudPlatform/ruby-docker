FROM google/ruby

WORKDIR /app
ONBUILD ADD Gemfile /app/Gemfile
ONBUILD ADD Gemfile.lock /app/Gemfile.lock
ONBUILD RUN ["/usr/bin/bundle", "install", "--deployment"]
ONBUILD ADD . /app

EXPOSE 8080
CMD []
ENV APPSERVER webrick
ENV RACK_ENV production
ENTRYPOINT /usr/bin/bundle exec rackup \
    -p 8080 /app/config.ru -s $APPSERVER -E $RACK_ENV
