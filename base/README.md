# google/ruby

[`google/ruby`](https://index.docker.io/u/google/ruby) is a [docker](https://docker.io) base image that bundles the stable version of [ruby](http://www.ruby-lang.org) installed from source.

It serves as a base for the [`google/ruby-runtime`](https://index.docker.io/u/google/ruby-runtime) and [`google/appengine-ruby`](https://index.docker.io/u/google/appengine-ruby) image.

## Usage

- Create a Gemfile in your ruby application directory with at least the following content.

         gem 'rack'

You can add other configurations to the Gemfile as you want.

- Create a Dockerfile in the same directory with the following content.

        FROM google/ruby

        WORKDIR /app
        ADD Gemfile /app/Gemfile
        ADD Gemfile.lock /app/Gemfile.lock
        RUN ["/usr/bin/bundle", "install"]
        ADD . /app
        
        CMD []
        ENTRYPOINT ["/usr/bin/bundle", "exec", "rackup", "/app/config.ru"]

- Run the following command in your application directory:

        docker build -t app .
