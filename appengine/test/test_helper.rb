# A set of helpful methods and assertions for running tests.

module TestHelper

  # Execute the given command in a shell.
  def execute_cmd(cmd)
    puts cmd
    system cmd
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
    actual = ""
    exit_code = 0
    0.upto(timeout) do |iter|
      puts cmd
      actual = `#{cmd}`
      exit_code = $?.exitstatus
      if exit_code == 0 && (expectation == nil || expectation === actual)
        return actual
      end
      puts("...expected result did not arrive yet (iteration #{iter})...")
      sleep(1)
    end
    flunk "Expected #{expectation.inspect} but got \"#{actual}\"" +
      " (exit code #{exit_code}) when executing \"#{cmd}\""
  end

end
