environment ENV.fetch("RAILS_ENV", "development")
bind "tcp://0.0.0.0:#{ENV['PORT'] || 3000}"
pidfile "/edidb/tmp/pids/puma.pid"
#threads 1,1
max_threads_count = ENV.fetch("RAILS_MAX_THREADS", 5)
min_threads_count = ENV.fetch("RAILS_MIN_THREADS") { max_threads_count }
threads min_threads_count, max_threads_count

on_worker_boot do
  Mongoid::Clients.clients.each_value do |client|
    client.close
    client.reconnect
  end
end

before_fork do
  Mongoid.disconnect_clients
end
