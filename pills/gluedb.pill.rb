BUS_DIRECTORY=File.join(File.dirname(__FILE__), "..")
LOG_DIRECTORY=File.join(BUS_DIRECTORY, "log")
PID_DIRECTORY=File.join(BUS_DIRECTORY, "pids")

HBXBUS_LOG = File.join(LOG_DIRECTORY, "gluedb_listeners.log")

def unset_list
  ev_list = [ 
    "RBENV_DIR",
    "GEM_PATH",
    "RBENV_PATH",
    "RBENV_GEMSET_ALREADY",
    "GEM_HOME",
    "RBENV_GEMSETS",
    "RBENV_HOOK_PATH",
    "RBENV_SHELL",
    "RBENV_VERSION"
  ]
  ev_list.map { |evv| "unset " + evv }.join(" && ")
end

def define_multi_worker(app, worker_n, worker_path, directory, number)
  (1..number).each do |num|
    worker_name = worker_n + "_" + num.to_s
    app.process(worker_name) do |process|
      worker_directory = directory
      # puts ENV.inspect
      process.start_command = "/bin/bash -l -c \"#{unset_list} && cd #{worker_directory} && export RBENV_GEMSETS=`cat #{worker_directory}/.rbenv-gemsets` && echo `env` > #{LOG_DIRECTORY}/#{worker_name}_envs.log && rbenv exec rails r -e production #{worker_path}\""
      process.stop_command = "/bin/kill -9 {{PID}}"
      process.start_grace_time 10.seconds
      process.pid_file = File.join(PID_DIRECTORY, "#{worker_name}.pid")
      process.daemonize = true
      process.working_dir = worker_directory
      process.stdout = process.stderr = File.join(LOG_DIRECTORY, "#{worker_name}.log")
    end
  end
end

Bluepill.application("gluedb_listeners", :log_file => HBXBUS_LOG) do |app|
  app.uid = "nginx"
  app.gid = "nginx"

#  define_multi_worker(app, "edi_ops_listener", "script/amqp/edi_ops_listener.rb", BUS_DIRECTORY, 1)
  define_multi_worker(app, "enrollment_creator", "script/amqp/enrollment_creator.rb", BUS_DIRECTORY, 1)
  define_multi_worker(app, "person_matcher", "script/amqp/person_matcher.rb", BUS_DIRECTORY, 1)
end
