# Executor for App Engine Flexible Environment

This is a wrapper Docker image that sets up an environment similar to the
[Google App Engine Flexible Environment](https://cloud.google.com/appengine/docs/flexible/),
suitable for running scripts and maintenance tasks provided by an application
deployed to App Engine. In particular, it ensures a suitable CloudSQL Proxy
is running in the environment.

Its driving use case is running production database migrations for Ruby on
Rails applications, and we expect similar uses for other languasges and
frameworks.

## Usage

This image is deployed to `gcr.io/google-appengine/exec-wrapper`, and is
designed to be run as a step in a
[Cloud Container Builder](https://cloud.google.com/container-builder/) job.
You must send, as arguments, the path of the deployed application image, any
environment variables to set, any Cloud SQL instances to make available, and
the command to run. Here is an example Cloud Build configuration:

    steps:
    - name: "gcr.io/google-appengine/exec-wrapper"
      args: ["-i", "gcr.io/my-project/appengine/some-long-name",
             "-e", "ENV_VARIABLE_1=value1", "-e", "ENV_2=value2",
             "-s", "my-project:us-central1:my_cloudsql_instance",
             "--", "bundle", "exec", "rake", "db:migrate"]

You can find the image path using `gcloud app versions describe`.

Ruby developers may use the [appengine gem](https://rubygems.org/gems/appengine)
for a convenient Rake-based interface.

## Building and testing

See the main readme in this repository for information on the build, test, and
release processes.
