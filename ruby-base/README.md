# [Base Image](http://cloud.google.com/ruby)

This is a [Docker](https://docker.com) base image that bundles stable versions of
[Ruby](http://ruby-lang.org) and [Bundler](http://bundler.io), and makes it
easy to containerize standard [Rack](http://rack.github.io) applications. It
is used primarily as the base image for deploying Ruby applications to
[Google App Engine Flexible](https://cloud.google.com/appengine/docs/flexible/).
It may also be used as a base image for running applications on
[Google Container Engine](https://cloud.google.com/container-engine) or any
other Docker host.

The image can be found at `l.gcr.io/google/ruby`
(or at `gcr.io/google-appengine/ruby` for deploying applications
to Google App Engine Flex).

## Usage

### With App Engine Flexible

App Engine Flexible supports any Ruby web application that uses
[Bundler](http://bundler.io) and thus has a `Gemfile`.

Often you can deploy a Ruby application to App Engine Flexible without having
to interact with Docker at all, by specifying `runtime: ruby` in your `app.yaml`
configuration file. For example:

```yaml
runtime: ruby
env: flex
entrypoint: bundle exec rackup -p $PORT

env_variables:
  SECRET_KEY_BASE: "1234567890MyLongSecretKey"
```

See the [documentation](https://cloud.google.com/appengine/docs/flexible/ruby/)
for more details on deploying Ruby applications to Google App Engine Flexible.

If you are using a
[custom runtime](https://cloud.google.com/appengine/docs/flexible/custom-runtimes/)
for a Ruby application, you may also use this image as the base image for your
Dockerfile.

### With Container Engine or other Docker hosts

For other Docker hosts, you may create a Dockerfile based on this image that
copies your application code, installs dependencies, and declares a command
or entrypoint.

For example, if you have a Rack-based application with a `config.ru` file, you
may use the following Dockerfile:

    # Use the Ruby base image
    FROM l.gcr.io/google/ruby:latest

    # Copy application files and install the bundle
    COPY . /app/
    RUN bundle install && rbenv rehash

    # Default container command invokes rackup to start the server.
    CMD ["bundle", "exec", "rackup", "--port=8080"]

See the next section on the design of the base image for more information on
what your Dockerfile should do.

For a full example on deploying a Ruby application to Google Container Engine, see [this tutorial](https://cloud.google.com/ruby/tutorials/bookshelf-on-container-engine).

## About the Ruby image

### Base image contents

This image is designed for Ruby web applications. It does the following:

- It installs a recent version of Debian, the system libraries needed by the
  standard Ruby runtime, and a recent version of [NodeJS](http://nodejs.org).
- It installs system libraries used by a number of commonly-used ruby gems
  such as database clients for ActiveRecord adapters. However, you should not
  depend on the actual list of libraries. As a best practice, your downstream
  Docker image should itself install any Debian packages needed by the ruby
  gems your application depends on.
- It installs [rbenv](https://github.com/sstephenson/rbenv) with the
  [ruby-build](https://github.com/sstephenson/ruby-build) plugin.
- It installs a recent supported version of the standard "MRI"
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
performed by your downstream Dockerfile:

- Use rbenv to install and select a specific ruby version, if you do not want
  to use the provided default.
- Install any native libraries needed by required gems.
- Copy application files into the `/app` directory.
- Run `bundle install`.
- Set the `CMD` or `ENTRYPOINT` if desired. (Note the base image leaves these
  unset.)

### Building the base image

Google regularly builds and releases this image at
`l.gcr.io/google/ruby` and `gcr.io/google-appengine/ruby`.

You may build the image yourself using Docker. In this directory, run:

    docker build -t my-ruby-base-image .

Replace `my-ruby-base-image` with the name of the image you wish to build.

To build and install in the Google Container Registry, you need the
[GCloud SDK](https://cloud.google.com/sdk) installed and configured and
authenticated for your project. Then, in this directory, run:

    gcloud container builds submit . --config cloudbuild.yaml \
      --substitutions _TAG=my-image-tag

Replace `my-image-tag` with the tag you wish to set. The image name will be
`ruby`. That is, the resulting image will be available as
`gcr.io/$YOUR_PROJECT/ruby:$YOUR_IMAGE_TAG`

You may do a local build and run the tests against it by running at the root
of this repository:

    rake test:base

### Contributing changes

See the CONTRIB.md file at the root of this repository.

### License

See the LICENSE file at the root of this repository.
