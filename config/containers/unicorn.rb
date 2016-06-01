app_path = ENV['RAILS_ROOT']
 
# Set the server's working directory
working_directory app_path
 
# Define where Unicorn should write its PID file
pid "#{app_path}/tmp/pids/unicorn.pid"
 
# Bind Unicorn to the container's default route, at port 3000
listen "0.0.0.0:3000"
 
# Define where Unicorn should write its log files
stderr_path "#{app_path}/log/unicorn.stderr.log"
stdout_path "#{app_path}/log/unicorn.stdout.log"
 
# Define the number of workers Unicorn should spin up.
# A new Rails app just needs one. You would scale this 
# higher in the future once your app starts getting traffic.
# See https://unicorn.bogomips.org/TUNING.html
worker_processes 1
 
# Make sure we use the correct Gemfile on restarts
before_exec do |server|
  ENV['BUNDLE_GEMFILE'] = "#{app_path}/Gemfile"
end
 
# Speeds up your workers.
# See https://unicorn.bogomips.org/TUNING.html
preload_app true
 
#
# Below we define how our workers should be spun up. 
# See https://unicorn.bogomips.org/Unicorn/Configurator.html
#
 
before_fork do |server, worker|
  # the following is highly recomended for Rails + "preload_app true"
  # as there's no need for the master process to hold a connection
  if defined?(ActiveRecord::Base)
    ActiveRecord::Base.connection.disconnect!
  end
 
  # Before forking, kill the master process that belongs to the .oldbin PID.
  # This enables 0 downtime deploys.
  old_pid = "#{server.config[:pid]}.oldbin"
  if File.exists?(old_pid) && server.pid != old_pid
    begin
      Process.kill("QUIT", File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
      # someone else did our job for us
    end
  end
end
 
after_fork do |server, worker|
  if defined?(ActiveRecord::Base)
    ActiveRecord::Base.establish_connection
  end
end
