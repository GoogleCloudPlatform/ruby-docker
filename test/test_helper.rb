# A set of helpful methods and assertions for running tests.

module TestHelper

  # Execute the given command in a shell.
  def execute_cmd(cmd)
    puts cmd
    system cmd
  end

  # Assert that the given file contents matches the given string or regex.
  def assert_file_contents(path, expectation)
    contents = ::IO.read(path)
    if expectation === contents
      contents
    else
      flunk "File #{path} did not contain #{expectation.inspect}"
    end
  end

  # Assert that execution of the given command produces a zero exit code.
  def assert_cmd_succeeds(cmd)
    puts cmd
    system cmd
    exit_code = $?.exitstatus
    if exit_code != 0
      flunk "Got exit code #{exit_code} when executing \"#{cmd}\""
    end
  end

  # Repeatedly execute the given command (with a pause between tries).
  # Flunks if it does not succeed and produce output matching the given
  # expectation (string or regex) within the given timeout in seconds.
  def assert_cmd_output(cmd, expectation, timeout=0)
    expectations = Array(expectation)
    actual = ""
    exit_code = 0
    0.upto(timeout) do |iter|
      puts cmd
      actual = `#{cmd}`
      exit_code = $?.exitstatus
      return actual if exit_code == 0 && expectations.all? { |e| e === actual }
      puts("...expected result did not arrive yet (iteration #{iter})...")
      sleep(1)
    end
    flunk "Expected #{expectation.inspect} but got \"#{actual}\"" +
      " (exit code #{exit_code}) when executing \"#{cmd}\""
  end

  # Assert that the given docker run command produces the given output.
  # Automatically cleans up the generated container.
  def assert_docker_output(args, expectation, container_root="generic")
    number = "%.08x" % rand(0x100000000)
    container = "ruby-test-container-#{container_root}-#{number}"
    begin
      assert_cmd_output("docker run --name #{container} #{args}", expectation)
    ensure
      execute_cmd("docker rm #{container}")
    end
  end

  # Runs a docker container as a daemon. Yields the container name.
  # Automatically kills and removes the container afterward.
  def run_docker_daemon(args, container_root="generic")
    number = "%.08x" % rand(0x100000000)
    container = "ruby-test-container-#{container_root}-#{number}"
    begin
      assert_cmd_succeeds("docker run --name #{container} -d #{args}")
      yield container
    ensure
      execute_cmd("docker kill #{container}")
      execute_cmd("docker rm #{container}")
    end
  end

  # Build a docker image with the given arguments. Yields the image name.
  # Automatically cleans up the generated image afterward.
  def build_docker_image(args, image_root="generic")
    number = "%.08x" % rand(0x100000000)
    image = "ruby-test-image-#{image_root}-#{number}"
    begin
      assert_cmd_succeeds("docker build -t #{image} #{args} .")
      yield image
    ensure
      execute_cmd("docker rmi #{image}")
    end
  end

end
