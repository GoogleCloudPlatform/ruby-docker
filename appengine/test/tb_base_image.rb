require "json"
require "minitest/autorun"
require_relative "../../test/test_helper"


# Runs structure tests defined in test_base_image.json locally.

class TestBaseImage < ::Minitest::Test

  include TestHelper

  BASE_DIR = ::File.dirname ::File.dirname __FILE__
  CONFIG_FILE = ::File.join BASE_DIR, "image_files/test_base_image.json"
  CONFIG_DATA = ::JSON.load ::IO.read CONFIG_FILE

  CONFIG_DATA["commandTests"].each do |test_config|
    define_method test_config["name"] do
      command_array = test_config["command"]
      binary = command_array.shift
      command = command_array.map{ |a| "'#{a}'" }.join(" ")
      expectations = test_config["expectedOutput"].map { |e| ::Regexp.new e }
      assert_docker_output \
          "--entrypoint=#{binary} appengine-ruby-base #{command}",
          expectations
    end
  end

end
