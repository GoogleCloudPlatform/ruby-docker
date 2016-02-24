
class TestHelper

  BASE_IMAGE_NAME = "appengine-ruby-base"


  def self.execute(cmd)
    puts("**** EXEC: #{cmd}")
    unless system(cmd)
      puts("**** ERR: exit code #{$?}")
      raise "failed"
    end
  end

  def self.execute_nocheck(cmd)
    puts("**** EXEC: #{cmd}")
    system(cmd)
  end

  def self.cwd(path=".")
    ::Dir.chdir(::File.expand_path(path, ::File.dirname(__FILE__))) do |p|
      puts("**** CWD: #{p}")
      yield
    end
  end

  def self.error(err)
    puts("**** ERR: #{err}")
    raise "failed"
  end


  def self.assert_cmd(cmd, expectation)
    wait_cmd(cmd, expectation, 0)
  end

  def self.wait_cmd(cmd, expectation, timeout)
    iter = 0
    loop do
      puts("**** EXEC: #{cmd}")
      actual = `#{cmd}`
      if $? == 0 && expectation === actual
        puts("**** OK: got epected value \"#{actual}\"")
        return actual
      end
      iter += 1
      if iter >= timeout
        puts("**** ERR: expected \"#{expectation}\" but got \"#{actual}\"")
        raise "failed"
      end
      puts("**** WAIT: expected value did not arrive yet (iteration #{iter})")
      sleep(1)
    end
  end


  def self.build_base_image
    cwd() do
      execute("docker build -t #{BASE_IMAGE_NAME} .")
    end
  end


  def self.run_tests(testcase)
    cwd("test") do
      if testcase
        if ::File.directory?(testcase)
          run_test_dir(testcase)
        else
          testfile = "#{testcase}.rb"
          if ::File.readable?(testfile)
            run_test_file(testfile)
          else
            error("Unknown testcase #{testcase}")
          end
        end
      else
        ::Dir.glob("*.rb").
            find_all{|f| !::File.directory?(f) && ::File.readable?(f)}.
            each{|f| run_test_file(f)}
        ::Dir.glob("*").
            find_all{|f| ::File.directory?(f)}.
            each{|f| run_test_dir(f)}
      end
    end
  end

  def self.run_test_file(file)
    puts "Loading testcase #{file}..."
    load file
  end

  def self.run_test_dir(dir)
    puts "Loading testcase #{dir}..."
    cwd("test/#{dir}") do
      num = rand(1000000)
      container_name = "ruby-app-#{num}"
      image_name = "appengine-ruby-test-#{num}"
      begin
        execute("docker build -t #{image_name} .")
        begin
          execute("docker run -d -p 8080:8080 --name #{container_name} #{image_name}")
          wait_cmd("curl -s -S http://127.0.0.1:8080/", "ruby app", 5)
        ensure
          execute_nocheck("docker kill #{container_name}")
          execute_nocheck("docker rm #{container_name}")
        end
      ensure
        execute_nocheck("docker rmi #{image_name}")
      end
    end
  end

end
