# Obsolete images

The following images are now obsolete:

*   [`google/ruby`](https://hub.docker.com/r/google/ruby/)
*   [`google/ruby-runtime`](https://hub.docker.com/r/google/ruby-runtime/)
*   [`google/ruby-hello`](https://hub.docker.com/r/google/ruby-hello/)

If you want to deploy a Ruby application to Google App Engine, you can simply specify "runtime: ruby" in your app.yaml configuration file.

If you'd like to extend the Ruby runtime for App Engine, use "gcr.io/google-appengine/ruby" as the base image.

See http://cloud.google.com/ruby for more information on using Ruby on Google Cloud Platform.

If you are looking for a generic Ruby base image, consider the [official Ruby image on DockerHub](https://hub.docker.com/_/ruby/).
