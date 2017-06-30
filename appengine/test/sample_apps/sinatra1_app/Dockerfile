FROM appengine-ruby-base
COPY Gemfile Gemfile.lock /app/
RUN bundle install && rbenv rehash
ENV GOOGLE_CLOUD_PROJECT=""
COPY . /app/
ENTRYPOINT bundle exec ruby myapp.rb -p 8080
