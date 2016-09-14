FROM gcr.io/google_appengine/base

ENV MESSAGE \\n\
********************************** NOTICE **********************************\\n\
\\n\
  The google/ruby images have been obsoleted.\\n\
\\n\
  If you want to deploy a Ruby application to Google App Engine, you can\\n\
  simply specify "runtime: ruby" in your app.yaml configuration file.\\n\
  If you'd like to extend the Ruby runtime for App Engine, use\\n\
  "gcr.io/google_appengine/ruby" as the base image.\\n\
  See http://cloud.google.com/ruby for more information on running Ruby on\\n\
  Google Cloud Platform.\\n\
\\n\
  If you are looking for a generic Ruby base image, consider the official\\n\
  Ruby image on DockerHub at https://hub.docker.com/_/ruby/\\n\
\\n\
********************************** NOTICE **********************************\\n\
\\n

# Prevent (most) docker runs of this image and print the above message.
ENTRYPOINT printf "$MESSAGE" && printf "ABORTING CONTAINER\\n\\n" && false

# Prevent inheriting of this image and print the above message.
ONBUILD RUN printf "$MESSAGE" && printf "ABORTING BUILD\\n\\n" && false
