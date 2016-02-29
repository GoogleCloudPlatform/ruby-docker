require "minitest/autorun"
require_relative "test_helper.rb"


# Basic tests on the content of the base image

class TestBaseImage < ::Minitest::Test

  include TestHelper


  def test_ruby_installation
    assert_cmd_output(
      "docker run --entrypoint=ruby appengine-ruby-base --version",
      /^ruby 2\.3\.0/)
  end

end
