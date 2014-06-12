# google/appengine-ruby

[`google/appengine-ruby`](https://index.docker.io/u/google/appengine-ruby) is a [docker](https://docker.io) base image for easily running App Engine [ruby](http://www.ruby-lang.org) application.

It can automatically bundle a Rack application and its dependencies with a single line Dockerfile.

It is based on [`google/ruby`](https://index.docker.io/u/google/ruby) base image.

## Usage

- Create a Dockerfile in your Rack application directory with the following content:

        FROM google/appengine-ruby

- Run the following command in your application directory:

        gcloud app run .

## Sample
  
See the [sources](/appengine-hello) for [`google/appengine-ruby-hello`](https://index.docker.io/u/google/appengine-ruby-hello) based on this image.

## Notes

The image assumes that your application:

- has a [Gemfile](http://bundler.io/gemfile.html) for [bundler](http://bundler.io) and the Gemfile contains rack.
- has config.ru for Rack.

When building your application docker image, `ONBUILD` triggers:

- Installes gems specified in the Gemfile and leverage docker caching appropriately
- Copy the application sources under the `/app` directory in the container
