FROM ${STAGING_IMAGE}

COPY . /app/

RUN cd /app && bundle install

ENTRYPOINT bundle exec ruby /app/myapp.rb

