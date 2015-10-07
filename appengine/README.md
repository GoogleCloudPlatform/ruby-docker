# google/ruby

[`gcr.io/google_appengine/ruby`](http://cloud.google.com/ruby) is a
[docker](https://docker.com) base image that bundles stable versions of
[Ruby](http://ruby-lang.org) and [Bundler](http://bundler.io), and makes it
easy to containerize standard [Rack](http://rack.github.io) applications.

## Usage

- Ensure your application has at least the following standard ruby application files.

    - `Gemfile` (with at least the Rack gem)
    - `Gemfile.lock`
    - `config.ru`

- Create a Dockerfile in your ruby application directory with the following content.

        FROM gcr.io/google_appengine/ruby
        COPY Gemfile Gemfile.lock /app/
        RUN bundle install && rbenv rehash
        COPY . /app/

- Run the following command in your application directory:

        docker build -t my/app .

- By default, the application will be started using `rackup` using the
  `webrick` web server in the `production` environment. You may customize this
  by adding `RACK_HANDLER` and/or `RACK_ENV` environment variables to your
  Dockerfile, or by providing your own `ENTRYPOINT`.
