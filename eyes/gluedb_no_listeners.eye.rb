BUS_DIRECTORY = File.join(File.dirname(__FILE__), "..")
LOG_DIRECTORY = File.join(BUS_DIRECTORY, "log")
PID_DIRECTORY = File.join(BUS_DIRECTORY, "pids")

BLUEPILL_LOG = File.join(LOG_DIRECTORY, "eye_gluedb.log")

Eye.config do
  logger BLUEPILL_LOG

  mail :host => "smtp4.dc.gov", :port => 25, :from_mail => "no-reply@dchbx.info"
  contact :tevans, :mail, 'trey.evans@dc.gov'
  contact :dthomas, :mail, 'dan.thomas@dc.gov'
end

class Eye::ChildProcess
  def name
    `ps -p #{pid} -o cmd=`.strip
  end
end

def start_command_for(worker_command)
  "bundle exec rails r -e production #{worker_command}"
end

def define_forked_worker(worker_n, worker_path, directory)
    worker_name = worker_n
    process(worker_name) do
      start_command start_command_for(worker_path)
      stop_on_delete true
      stop_signals [:TERM, 10.seconds, :KILL]
      start_timeout 15.seconds
      pid_file File.join(PID_DIRECTORY, "#{worker_name}.pid")
      daemonize true
      working_dir directory
      stdall File.join(LOG_DIRECTORY, "#{worker_name}.log")
      monitor_children do
        stop_command "kill -QUIT {PID}"
        check :cpu, :every => 30, :below => 80, :times => 3
        check :memory, :every => 30, :below => 500.megabytes, :times => [4,7]
      end
    end
end

def define_forked_heavy_worker(worker_n, worker_path, directory)
    worker_name = worker_n
    process(worker_name) do
      start_command start_command_for(worker_path)
      stop_on_delete true
      stop_signals [:TERM, 10.seconds, :KILL]
      start_timeout 15.seconds
      pid_file File.join(PID_DIRECTORY, "#{worker_name}.pid")
      daemonize true
      working_dir directory
      stdall File.join(LOG_DIRECTORY, "#{worker_name}.log")
      monitor_children do
        stop_command "kill -QUIT {PID}"
#        check :cpu, :every => 30, :below => 80, :times => 3
        check :memory, :every => 30, :below => 500.megabytes, :times => [4,7]
      end
    end
end

def define_forked_largemem_worker(worker_n, worker_path, directory)
    worker_name = worker_n
    process(worker_name) do
      start_command start_command_for(worker_path)
      stop_on_delete true
      stop_signals [:TERM, 10.seconds, :KILL]
      start_timeout 15.seconds
      pid_file File.join(PID_DIRECTORY, "#{worker_name}.pid")
      daemonize true
      working_dir directory
      stdall File.join(LOG_DIRECTORY, "#{worker_name}.log")
      monitor_children do
        stop_command "kill -QUIT {PID}"
#        check :cpu, :every => 30, :below => 80, :times => 3
        check :memory, :every => 30, :below => 800.megabytes, :times => [4,7]
      end
    end
end

def define_multi_worker(worker_n, worker_path, directory, number)
  (1..number).each do |num|
    worker_name = worker_n + "_" + num.to_s
    process(worker_name) do
      start_command start_command_for(worker_path)
      stop_on_delete true
      stop_signals [:TERM, 10.seconds, :KILL]
      start_timeout 15.seconds
      pid_file File.join(PID_DIRECTORY, "#{worker_name}.pid")
      daemonize true
      working_dir directory
      stdall File.join(LOG_DIRECTORY, "#{worker_name}.log")
      check :cpu, :every => 30, :below => 80, :times => 3
      check :memory, :every => 30, :below => 500.megabytes, :times => [4,7]
    end
  end
end

Eye.application 'eye_gluedb' do
  notify :tevans, :info
#  notify :dthomas, :info

  process("unicorn") do
    working_dir BUS_DIRECTORY
    pid_file "pids/unicorn.pid"
    start_command "bundle exec unicorn_rails -c #{BUS_DIRECTORY}/config/unicorn.rb -E production -D"
    stdall "log/unicorn.log"

    # stop signals:
    #     # http://unicorn.bogomips.org/SIGNALS.html
    stop_signals [:TERM, 10.seconds]
    #
    #             # soft restart
    #    restart_command "kill -USR2 {PID}"
    #
    # check :cpu, :every => 30, :below => 80, :times => 3
    # check :memory, :every => 30, :below => 150.megabytes, :times => [3,5]
    #
    start_timeout 30.seconds
    restart_grace 30.seconds
    #
    monitor_children do
      stop_command "kill -QUIT {PID}"
      check :cpu, :every => 30, :below => 80, :times => 3
      check :memory, :every => 30, :below => 500.megabytes, :times => [4,7]
    end
  end
end
