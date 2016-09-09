FROM gcr.io/google_appengine/base

ENV MESSAGE \\n\
********************************** NOTICE **********************************\\n\
\\n\
  The google/ruby images have been obsoleted.\\n\
\\n\
  If you want to deploy a Ruby application to Google App Engine, please use\\n\
  gcr.io/google_appengine/ruby as your base image.\\n\
\\n\
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
