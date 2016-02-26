# A set of helpful methods for running tests.

class TestHelper

  def initialize(opts)
    @verbose = opts[:verbose]
  end


  # Output a status message to the console, if in verbose mode.
  def print_status(str)
    puts("**** #{str}") if @verbose
  end

  # Execute the given command in a shell. Fail the test
  # (i.e. raise an exception) if it returns a non-zero exit code.
  def execute(cmd)
    print_status("Executing: #{cmd}")
    unless system(cmd)
      raise "Exit code #{$?} when running: #{cmd}"
    end
  end

  # Execute the given command in a shell. Return the error code.
  def execute_nocheck(cmd)
    print_status("Executing: #{cmd}")
    system(cmd)
    $?
  end

  # Change the working directory for the provided block. The path given
  # is relative to the test directory.
  def cwd(path=".")
    ::Dir.chdir(::File.expand_path(path, ::File.dirname(__FILE__))) do |p|
      print_status("Changing dir: #{p}")
      yield
    end
  end

  # Raise the given error message
  def error(err)
    raise err
  end

  # Assert that a single execution of the given command produces an output
  # matching the given expectation
  def assert_cmd(cmd, expectation)
    wait_cmd(cmd, expectation, 0)
  end

  # Repeatedly execute the given command (with a pause between tries).
  # Raises an error if it does not produce output matching the given
  # expectation within the given timeout in seconds.
  def wait_cmd(cmd, expectation, timeout)
    iter = 0
    loop do
      print_status("Executing: #{cmd}")
      actual = `#{cmd}`
      exit_code = $?
      if exit_code == 0 && expectation === actual
        print_status("OK: got epected value \"#{actual}\"")
        return actual
      end
      iter += 1
      if iter >= timeout
        raise "Expected \"#{expectation}\" but got \"#{actual}\" (exit code #{exit_code})"
      end
      print_status("Expected value did not arrive yet (iteration #{iter})")
      sleep(1)
    end
  end

end
