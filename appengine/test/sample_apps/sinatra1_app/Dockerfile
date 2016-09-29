FROM appengine-ruby-base
COPY Gemfile Gemfile.lock /app/
RUN bundle install && rbenv rehash
COPY . /app/
ENTRYPOINT bundle exec ruby myapp.rb -p 8080
