require "minitest/autorun"
require_relative "test_helper"


# Tests of a bunch of sample apps. Treats every subdirectory of the test
# directory that contains a Dockerfile as a sample app. Builds the docker
# image, runs the server, and hits the root of the server, expecting the
# string "ruby app" to be returned.
#
# This is supposed to exercise the base image extended in various ways, so
# the sample app Dockerfiles should all inherit FROM the base image, which
# will be called "appengine-ruby-base".

class TestSampleApps < ::Minitest::Test

  include TestHelper

  APPS_DIR = ::File.join(::File.dirname(__FILE__), "sample_apps")


  ::Dir.glob("#{APPS_DIR}/*/Dockerfile").each do |dockerfile|
    test_dir = ::File.dirname(dockerfile)
    base_name = ::File.basename(test_dir)
    define_method("test_#{base_name}") do
      run_app_test(base_name)
    end
  end


  def run_app_test(dirname)
    puts("**** Testing app: #{dirname}")
    ::Dir.chdir(::File.join(APPS_DIR, dirname)) do |dir|
      build_docker_image("", dirname) do |image|
        run_docker_daemon("-p 8080:8080 #{image}") do |container|
          assert_cmd_output("docker run --link #{container}:#{container} gcr.io/google-appengine/debian8 /bin/bash -c 'apt-get -qq update > /dev/null 2>&1; apt-get -qq -y install curl > /dev/null 2>&1; curl -s -S #{container}:8080/'", "ruby app", 15)
        end
      end
    end
  end

end
