# gcr.io/google_appengine/ruby

[`gcr.io/google_appengine/ruby`](http://cloud.google.com/ruby) is a
[Docker](https://docker.com) base image that bundles stable versions of
[Ruby](http://ruby-lang.org) and [Bundler](http://bundler.io), and makes it
easy to containerize standard [Rack](http://rack.github.io) applications.

## About this image

This image is designed for Ruby Rack applications. It does the following:

- It installs a recent version of Debian, the system libraries needed by the
  standard Ruby runtime, and a recent version of [NodeJS](http://nodejs.org).
- It installs [rbenv](https://github.com/sstephenson/rbenv) with the
  [ruby-build](https://github.com/sstephenson/ruby-build) plugin.
- Using ruby-build, it installs several recent supported versions of the
  standard Ruby runtime. With each runtime, it installs a recent version of
  [bundler](http://bundler.io) and [foreman](https://github.com/ddollar/foreman).
- It sets the working directory to `/app` and exposes port 8080.
- It configures a standard `ENTRYPOINT` which runs `rackup` on port 8080,
  assuming that an appropriate `/app/config.ru` is present.

The following tasks are _not_ handled by this base image, and should be
performed by your inheriting Dockerfile:

- Use rbenv to install a custom ruby runtime, if desired.
- Install any native libraries needed by required gems.
- Copy application files into the `/app` directory.
- Run `bundle install`.
- Replace `ENTRYPOINT` with a custom application launch command, if desired.

## Usage Example

- Create a Ruby application -- using, for example,
  [Ruby on Rails](http://rubyonrails.org). The application should include at
  least the following files:

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
