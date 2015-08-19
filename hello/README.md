# google/ruby-hello

[`google/ruby-hello`](https://index.docker.io/u/google/ruby-hello) is a [docker](https://docker.com) image for the [Rack](http://http://rack.github.io/) hello world application.

It is based on the `gcr.io/google_appengine/base` base image and listens on port 8080.

## Usage

- Run the following commands in this directory.

        docker build -t my/ruby-hello
        docker run -p 8080:8080 my/ruby-hello
