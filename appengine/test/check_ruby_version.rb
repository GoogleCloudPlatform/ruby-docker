TestHelper.assert_cmd(
  "docker run --entrypoint=ruby appengine-ruby-base --version",
  /^ruby 2\.3\.0/)
