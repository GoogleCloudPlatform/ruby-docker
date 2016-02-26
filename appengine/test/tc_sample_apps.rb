require "minitest/autorun"
require "#{::File.dirname(__FILE__)}/test_helper.rb"


# Tests of a bunch of sample apps. Treats every subdirectory of the test
# directory that contains a Dockerfile as a sample app. Builds the docker
# image, runs the server, and hits the root of the server, expecting the
# string "ruby app" to be returned.
#
# This is supposed to exercise the base image extended in various ways, so
# the sample app Dockerfiles should all inherit FROM the base image, which
# will be called "appengine-ruby-base".

class TestSampleApps < ::Minitest::Test

  HELPER = TestHelper.new(verbose: ::ENV['VERBOSE'])


  ::Dir.glob("#{::File.dirname(__FILE__)}/*/Dockerfile").each do |dockerfile|
    test_dir = ::File.dirname(dockerfile)
    base_name = ::File.basename(test_dir)
    define_method("test_#{base_name}") do
      run_app_test(base_name)
    end
  end


  def run_app_test(dirname)
    HELPER.print_status("Testing app: #{dirname}")
    HELPER.cwd(dirname) do
      num = rand(1000000)
      container = "ruby-app-#{num}"
      image = "appengine-ruby-test-#{num}"
      begin
        HELPER.execute("docker build -t #{image} .")
        begin
          HELPER.execute(
              "docker run -d -p 8080:8080 --name #{container} #{image}")
          HELPER.wait_cmd("curl -s -S http://127.0.0.1:8080/", "ruby app", 5)
        ensure
          HELPER.execute_nocheck("docker kill #{container}")
          HELPER.execute_nocheck("docker rm #{container}")
        end
      ensure
        HELPER.execute_nocheck("docker rmi #{image}")
      end
    end
  end

end
