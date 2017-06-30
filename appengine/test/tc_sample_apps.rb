require "minitest/autorun"
require_relative "../../test/test_helper"


# Tests of a bunch of sample apps. Treats every subdirectory of the test
# directory that contains a Dockerfile as a sample app. Builds the docker
# image, runs the server, and hits the root of the server, expecting the
# string "Hello World!" to be returned.
#
# This is supposed to exercise the base image extended in various ways, so
# the sample app Dockerfiles should all inherit FROM the base image, which
# will be called "appengine-ruby-base".

class TestSampleApps < ::Minitest::Test

  include TestHelper

  TEST_DIR = ::File.dirname __FILE__
  BASE_DIR = ::File.dirname ::File.dirname TEST_DIR
  DOCKERFILES_DIR = ::File.join TEST_DIR, "sample_apps"
  APPS_DIR = ::File.join BASE_DIR, "test/sample_apps"
  TMP_DIR = ::File.join TEST_DIR, "tmp"


  ::Dir.glob("#{DOCKERFILES_DIR}/*/Dockerfile").each do |dockerfile|
    test_dir = ::File.dirname dockerfile
    base_name = ::File.basename test_dir
    define_method "test_#{base_name}" do
      run_app_test base_name
    end
  end


  def run_app_test app_name
    puts "**** Testing app: #{app_name}"

    app_dir = ::File.join APPS_DIR, app_name
    dockerfile_dir = ::File.join DOCKERFILES_DIR, app_name
    assert_cmd_succeeds "rm -rf #{TMP_DIR}"
    assert_cmd_succeeds "cp -r #{app_dir} #{TMP_DIR}"
    assert_cmd_succeeds "cp #{dockerfile_dir}/Dockerfile #{TMP_DIR}/"

    ::Dir.chdir TMP_DIR do |dir|
      build_docker_image "", app_name do |image|
        run_docker_daemon "-p 8080:8080 #{image}" do |container|
          assert_cmd_output \
              "docker exec #{container} curl -s -S http://127.0.0.1:8080",
              "Hello World!", 10
        end
      end
    end
  end

end
