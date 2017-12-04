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

This repository also contains a helper image, "app-engine-exec-wrapper" that
provides a way to execute scripts in an App Engine application's environment.
See the `app-engine-exec-wrapper` directory for more details.

## Building and testing

The provided Rakefile builds all the images locally and runs the unit tests
in the test directory. It requires Ruby 2.3 and Docker 17.06 or later.

Release candidate test builds can be built using the `build-ruby-runtime-*`
scripts. To perform a test build of all the runtime images into the current
gcloud project:

    ./build-ruby-runtime-images.sh

Typically you may also want to pass the `-s` flag to tag the images with the
`staging` tag. Pass the `-h` flag for more information about the options.

To perform a test build of the runtime pipeline config to a GCS bucket:

    ./build-ruby-runtime-pipeline.sh -b my-bucket-name

Official release builds of the Ruby Runtime are generally performed internally
at Google, using those build scripts.

Official builds of the exec wrapper are done using the
`build-app-engine-exec-wrapper.sh` and `release-app-engine-exec-wrapper.sh`
scripts. If you have sufficient permissions, you can perform an official
release as follows:

    ./build-app-engine-exec-wrapper.sh -p google-appengine -s
    ./release-app-engine-exec-wrapper.sh -p google-appengine

The `integration_test` directory contains sample applications that are used
by the Google Ruby team for runtime integration tests.

## Contributing changes

* See [CONTRIB.md](CONTRIB.md)

## License

* See [LICENSE](LICENSE)
