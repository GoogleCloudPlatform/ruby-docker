# google/ruby

`gcr.io/google_appengine/ruby` is a [docker](https://docker.com) base image that bundles stable versions of [Ruby](http://ruby-lang.org) and [Bundler](http://bundler.io), and makes it easy to containerize standard [Rack](http://rack.github.io) applications.

## Usage

- Create a Dockerfile in your ruby application directory with the following content.

        FROM gcr.io/google_appengine/ruby

- Ensure your application has at least the following standard ruby application files.

    - `Gemfile` (with at least the Rack gem)
    - `Gemfile.lock`
    - `config.ru`

- Run the following command in your application directory:

        docker build -t my/app .

## Notes

When building your application's docker image, `ONBUILD` performs the following:

- It installs the gems specified in your `Gemfile.lock`
- It copies all files in the current directory (besides any skipped due to
  a `.dockerignore` file) into the container.
- It sets the `ENTRYPOINT` to run rackup on port 8080.

By default, your application is run in the Webrick web server. If you want to
run in an alternate server, include it in your `Gemfile` and set the
`RACK_HANDLER` environment variable to specify the server to use. For example,
to run in Puma, include the `puma` gem in your `Gemfile`, and include the
following in your application's Dockerfile:

    ENV RACK_HANDLER puma

By default, the rack environment is set to `production`. To use a different
environment, set the `RACK_ENV` environment variable in your Dockerfile, e.g.:

    ENV RACK_ENV staging

You may also override the `ENTRYPOINT` in your Dockerfile.
