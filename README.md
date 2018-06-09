# Ruby Runtime for Google Cloud Platform

[![Travis-CI Build Status](https://travis-ci.org/GoogleCloudPlatform/ruby-docker.svg)](https://travis-ci.org/GoogleCloudPlatform/ruby-docker/)

This repository contains the source for the Ruby runtime for
[Google App Engine Flexible](https://cloud.google.com/appengine/docs/flexible/).

For more information on using the Ruby runtime, see
https://cloud.google.com/appengine/docs/flexible/ruby/

## Contents

This repository includes:

* The base image atop Ubuntu 16_04, including the OS, common libraries and
  build dependencies, NodeJS, and rbenv, in the `ruby-ubuntu16` directory.
* A Dockerfile and config for building Ruby binary images in the
  `ruby-prebuilt` directory.
* A convenience image, including the above Ubuntu image and a default
  installation of Ruby, in the `ruby-base` directory.
* A raw image that contains installations of some common build tools and
  scripts, such as Yarn, the Google Cloud SQL Proxy, and the Google Cloud SDK,
  in the `ruby-build-tools` directory.
* An image that analyzes a Ruby application and generates an appropriate
  Dockerfile, in the `ruby-generate-dockerfile` directory.
* Templates for the Ruby runtime build pipeline definition in the
  `ruby-pipeline` directory.

This repository also contains a helper image, "app-engine-exec-wrapper" that
provides a way to execute scripts in an App Engine application's environment.
See the `app-engine-exec-wrapper` directory for more details.

The `integration_test` directory contains sample applications that are used
by the Google Ruby team for runtime integration tests.

## Local builds and tests

The provided Rakefile builds all the images locally and runs the unit tests
in the test directory. It requires Ruby 2.3 and Docker 17.06 or later.

To perform a local build and test:

    bundle install
    bundle exec rake

Note this procedure tests against production prebuilt Ruby binaries by default.
To create and test locally-built binaries:

    USE_LOCAL_PREBUILT=true bundle exec rake

## Release builds

Release candidates can be built using the `build-*.sh` scripts. Generally, they
build artifacts, tagged with a build number, to a specified project (defaulting
to the current gcloud project). Builds can be released using the `release-*.sh`
scripts, which generally just retag a specified build as latest. Each of these
scripts accepts a `-h` flag which documents the options.

### Runtime images

To build and release runtime images, use the `build-ruby-runtime-images.sh` and
`release-ruby-runtime-images.sh` scripts.
When building, you may want to set the `-s` flag to tag the build as staging,
and the `-i` flag to use a prebuilt binary for the convenience base image.

Official release builds of the runtime images are generally performed
internally at Google. Such builds are roughly equivalent to:

    ./build-ruby-runtime-images.sh -i -p gcp-runtimes -s
    ./release-ruby-runtime-images.sh -p gcp-runtimes

### Prebuilt binaries

To build and release prebuilt binary images, use the
`build-ruby-binary-images.sh` and `release-ruby-binary-images.sh` scripts.
When building, you should either set the `-c` flag or provide a
`prebuilt-versions.txt` file to tell the runtime which Rubies to build. You may
also want to set the `-s` flag to mark the new images as staging.

Official release builds of the prebuilt binaries are generally performed
internally at Google. Such builds are roughly equivalent to:

    ./build-ruby-binary-images.sh -p gcp-runtimes -s -c <versions>
    ./release-ruby-binary-images.sh -p gcp-runtimes -c <versions>

### Runtime pipeline

To build and release the runtime pipeline config, use the
`build-ruby-runtime-pipeline.sh` and `release-ruby-runtime-pipeline.sh` scripts.
The `-b` flag is required. You may also want to set the `-s` flag to tag the
pipeline build as staging. Finally, you should either set the `-c` flag, or
provide a `prebuilt-versions.txt` file to tell the runtime which Rubies are
prebuilt.

Official release builds of the pipeline are generally performed internally at
at Google. Such builds are roughly equivalent to:

    ./build-ruby-runtime-pipeline.sh -b gcp-runtimes -p gcp-runtimes -s
    ./release-ruby-runtime-pipeline.sh -b gcp-runtimes -p gcp-runtimes

### Exec Wrapper

To build and release the exec wrapper, use the
`build-app-engine-exec-wrapper.sh` and `release-app-engine-exec-wrapper.sh`
scripts. You may also want to set the `-s` flag to tag the build as staging.

Official release builds of the wrapper are generally performed internally at
at Google. Such builds are roughly equivalent to:

    ./build-app-engine-exec-wrapper.sh -p google-appengine -s
    ./release-app-engine-exec-wrapper.sh -p google-appengine

## Contributing changes

* See [CONTRIB.md](CONTRIB.md)

## License

* See [LICENSE](LICENSE)
