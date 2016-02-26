require "minitest/autorun"
require "#{::File.dirname(__FILE__)}/test_helper.rb"


# Basic tests on the content of the base image

class TestBaseImage < ::Minitest::Test

  HELPER = TestHelper.new(verbose: ::ENV['VERBOSE'])


  def test_ruby_installation
    HELPER.assert_cmd(
      "docker run --entrypoint=ruby appengine-ruby-base --version",
      /^ruby 2\.3\.0/)
  end

end
