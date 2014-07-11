FROM google/ruby

WORKDIR /app
ONBUILD ADD Gemfile /app/Gemfile
ONBUILD RUN ["/usr/bin/bundle", "install"]
ONBUILD ADD . /app

EXPOSE 8080
CMD []
ENV APPSERVER webrick
ENTRYPOINT /usr/bin/bundle exec rackup -p 8080 /app/config.ru -s $APPSERVER
