# google/ruby

[`google/ruby`](https://index.docker.io/u/google/ruby) is a [docker](https://docker.io) base image that bundles the stable version of [ruby](http://www.ruby-lang.org) installed from source.

It serves as a base for the [`google/ruby-runtime`](https://index.docker.io/u/google/ruby-runtime) and [`google/appengine-ruby`](https://index.docker.io/u/google/appengine-ruby) image.

## Usage

- Create a Dockerfile in your ruby application directory with the following content:

        FROM google/ruby

        WORKDIR /app
        RUN gem install rack
        ADD . /app
        
        CMD []
        ENTRYPOINT ["/usr/local/bin/rackup", "/app/config.ru"]

- Run the following command in your application directory:

        docker build -t app .
