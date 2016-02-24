FROM appengine-ruby-base
COPY Gemfile Gemfile.lock /app/
RUN bundle install && rbenv rehash
COPY . /app/
ENTRYPOINT bundle exec rackup -p 8080 -E production config.ru
