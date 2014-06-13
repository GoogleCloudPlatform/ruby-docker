FROM google/ruby

WORKDIR /app
ONBUILD ADD Gemfile /app/Gemfile
ONBUILD RUN ["/usr/local/bin/bundle", "install"]
ONBUILD ADD . /app

EXPOSE 8080
CMD []
ENTRYPOINT ["/usr/local/bin/bundle", "exec", "rackup", "-p", "8080", "/app/config.ru"]
