# gcr.io/google_appengine/ruby

[`gcr.io/google_appengine/ruby`](http://cloud.google.com/ruby) is a
[Docker](https://docker.com) base image that bundles stable versions of
[Ruby](http://ruby-lang.org) and [Bundler](http://bundler.io), and makes it
easy to containerize standard [Rack](http://rack.github.io) applications. It
is used primarily as a base image for deploying Ruby applications to the
[Google App Engine flexible environment](https://cloud.google.com/appengine/docs/flexible/ruby/).

## About this image

This image is designed for Ruby web applications. It does the following:

- It installs a recent version of Debian, the system libraries needed by the
  standard Ruby runtime, and a recent version of [NodeJS](http://nodejs.org).
- It installs system libraries used by a number of commonly-used ruby gems
  such as database clients for ActiveRecord adapters. However, the actual
  list of libraries is subject to change. As a best practice, your downstream
  Docker image should itself install any Debian packages needed by the ruby
  gems your application depends on.
- It installs [rbenv](https://github.com/sstephenson/rbenv) with the
  [ruby-build](https://github.com/sstephenson/ruby-build) plugin.
- It installs a recent supported version of the standard
  [Ruby interpreter](http://ruby-lang.org/) and configures rbenv to use it by
  default. It also installs a recent version of [bundler](http://bundler.io).
- It sets the working directory to `/app` and exposes port 8080.
- It sets some standard environment variables commonly used for production
  web applications, especially in a cloud hosting environment. These include:
  - `PORT=8080`
  - `RACK_ENV=production`
  - `RAILS_ENV=production`
  - `APP_ENV=production`
  - `RAILS_SERVE_STATIC_FILES=true`
  - `RAILS_LOG_TO_STDOUT=true`

The following tasks are _not_ handled by this base image, and should be
performed by your inheriting Dockerfile:

- Use rbenv to install and select a custom ruby runtime, if desired.
- Install any native libraries needed by required gems.
- Copy application files into the `/app` directory.
- Run `bundle install`.
- Set the `CMD` or `ENTRYPOINT` if desired. (Note the base image leaves these
  unset.)

## Usage Example

First, create a Ruby application. For example, a simple Rack-based application
might include the following files:

- `Gemfile` (with at least the Rack gem)
- `Gemfile.lock`
- `config.ru`

Next, create a Dockerfile in your ruby application directory with the following
content.

    FROM gcr.io/google_appengine/ruby
    COPY . /app/
    RUN bundle install && rbenv rehash
    CMD ["bundle", "exec", "rackup", "--port=$PORT", "--env=$RACK_ENV"]

Run the following command in your application directory to build the image.

    docker build -t my/app .

Start the server

    docker run -d my/app
