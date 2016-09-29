require "minitest/autorun"
require_relative "test_helper"


# Tests of the supported ruby versions. Ensures that all supported ruby
# versions can be installed and will execute.

class TestRubyVersions < ::Minitest::Test

  VERSIONS = [
    # 2.0 is obsolete, but we keep it for testing patchlevel notation and
    # installation from source.
    "2.0.0-p648",
    # 2.1.x versions are currently supported.
    "2.1.0",
    "2.1.1",
    "2.1.2",
    "2.1.3",
    "2.1.4",
    "2.1.5",
    "2.1.6",
    "2.1.7",
    "2.1.8",
    "2.1.9",
    "2.1.10",
    # 2.2.x versions are currently supported.
    "2.2.0",
    "2.2.1",
    "2.2.2",
    "2.2.3",
    "2.2.4",
    "2.2.5",
    # 2.3.x versions are currently supported.
    "2.3.0",
    "2.3.1",
    # Test for no requested version (i.e. fall back to default)
    ""
  ]


  include TestHelper

  DATA_DIR = ::File.join(::File.dirname(__FILE__), "ruby_versions")

  VERSIONS.each do |version|
    mangled_version = version.gsub(".", "_").gsub("-", "_")
    mangled_version = "default_version" if mangled_version == ""
    define_method("test_#{mangled_version}") do
      run_version_test(version, mangled_version)
    end
  end


  def run_version_test(version, mangled_version)
    puts("**** Testing ruby version: #{version}")
    version_output = version.gsub("-", "").gsub(".", "\\.")
    ::Dir.chdir(DATA_DIR) do |dir|
      build_docker_image(
          "--build-arg REQUESTED_RUBY_VERSION=#{version}",
          mangled_version) do |image|
        assert_docker_output(image, /ruby\s#{version_output}/, mangled_version)
      end
    end
  end

end
