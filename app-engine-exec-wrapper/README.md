# Executor for App Engine Flexible Environment

This is a wrapper Docker image that sets up an environment similar to the
[Google App Engine Flexible Environment](https://cloud.google.com/appengine/docs/flexible/),
suitable for running scripts and maintenance tasks provided by an application
deployed to App Engine. In particular, it ensures a suitable Cloud SQL Proxy
is running in the environment.

Its driving use case is running production database migrations for Ruby on
Rails applications, but it is also useful for Django applications, and we
expect similar uses for other languages and frameworks.

## Usage

This image is deployed to `gcr.io/google-appengine/exec-wrapper`, and is
designed to be run as a step in a
[Cloud Build](https://cloud.google.com/cloud-build/) job.
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

## Usage for Cloud Run

This wrapper can also be used for applications deployed to Cloud Run by defining
your image name in the arguments. It would typically be added after your image build and image push steps"

    steps:
    ...
    - name: "gcr.io/google-appengine/exec-wrapper"
      args: ["-i", "gcr.io/my-project/my-image",
             ...]


If the Cloud Run image is built with [Google Cloud Buildpacks](https://github.com/GoogleCloudPlatform/buildpacks),
you must define an entrypoint. By default you can use the `launcher` entrypoint: 


    steps:
    ...
    - name: "gcr.io/google-appengine/exec-wrapper"
      args: [...
             "-r", "launcher", 
             "--", "bundle", "exec", "rake", "db:migrate"]

Alternatively, you can define your migration command as an entrypoint in `Procfile`,
and use that instead of a direct command: 

    # Procfile
    web: bundle exec rails server
    migrate: bundle exec rake db:migrate

    # cloudbuild.yaml
    steps:
    ...
    - name: "gcr.io/google-appengine/exec-wrapper"
      args: [...
             "-r", "migrate"]

## Building and testing

See the main readme in this repository for information on the build, test, and
release processes.
