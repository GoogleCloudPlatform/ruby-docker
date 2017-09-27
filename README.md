# Ruby Runtime for Google Cloud Platform

[![Travis-CI Build Status](https://travis-ci.org/GoogleCloudPlatform/ruby-docker.svg)](https://travis-ci.org/GoogleCloudPlatform/ruby-docker/)

This repository contains the source for the Ruby runtime for
[Google App Engine Flexible](https://cloud.google.com/appengine/docs/flexible/).
It comprises:

* The base image in the `ruby-base` directory.
* A raw image that contains installations of some common build tools and
  scripts, including NodeJS, Yarn, and the Google CloudSQL Proxy, in the
  `ruby-build-tools` directory.
* An image that analyzes a Ruby application and generates an appropriate
  Dockerfile, in the `ruby-generate-dockerfile` directory.
* Templates for the Ruby runtime build pipeline definition in the
  `ruby-pipeline` directory.

For more information on using the Ruby runtime, see
https://cloud.google.com/ruby

## Building and testing

The provided Rakefile builds the three images locally and runs the unit tests
in the test directory. It requires Ruby 2.3 and Docker 17.06 or later.

Actual builds can be done using the build scripts in this directory. The
`build-ruby-runtime-images.sh` script uses Google Cloud Container Builder to
build the images and upload them to Google Container Registry. The
`build-ruby-runtime-pipeline.sh` script creates a Ruby runtime builder
configuration and uploads it to Google Cloud Storage where it can be used.

The `integration_test` directory contains a sample application that is used
by the Google Ruby team for internal integration tests.

## Contributing changes

* See [CONTRIB.md](CONTRIB.md)

## License

* See [LICENSE](LICENSE)
