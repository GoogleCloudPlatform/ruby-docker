require "minitest/autorun"
require_relative "test_helper"


# Basic tests on the content of the base image

class TestBaseImage < ::Minitest::Test

  include TestHelper


  def test_rbenv_installation
    assert_docker_output(
      "--entrypoint=rbenv appengine-ruby-base global",
      /^\d+\.\d+\.\d+/,
      "rbenv_installation")
  end


  def test_bundler_installation
    assert_docker_output(
      "--entrypoint=bundle appengine-ruby-base version",
      /^Bundler\sversion\s\d+\.\d+/,
      "bundler_installation")
  end


  def test_node_execution
    assert_docker_output(
      "--entrypoint=node appengine-ruby-base" +
        " -e 'console.log(\"Ruby on Google Cloud Platform\")'",
      "Ruby on Google Cloud Platform\n",
      "node_execution")
  end


  def test_ruby_execution
    assert_docker_output(
      "--entrypoint=ruby appengine-ruby-base" +
        " -e 'puts \"Ruby on Google Cloud Platform\"'",
      "Ruby on Google Cloud Platform\n",
      "ruby_execution")
  end


  def test_environment_variables
    assert_docker_output(
      "--entrypoint=ruby appengine-ruby-base -e 'puts ENV[\"RACK_ENV\"]'",
      "production\n",
      "rack_env")
    assert_docker_output(
      "--entrypoint=ruby appengine-ruby-base -e 'puts ENV[\"RAILS_ENV\"]'",
      "production\n",
      "rails_env")
  end

end
