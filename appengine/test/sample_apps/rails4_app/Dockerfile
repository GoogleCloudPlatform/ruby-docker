FROM appengine-ruby-base
COPY Gemfile Gemfile.lock /app/
RUN bundle install && rbenv rehash
COPY . /app/
ENV SECRET_KEY_BASE=a12345
ENTRYPOINT bundle exec bin/rails server -p 8080
