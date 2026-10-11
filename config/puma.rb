# frozen_string_literal: true

# Puma can serve each request in a thread from an internal thread pool.
# The `threads` method setting takes two numbers: a minimum and maximum.
# Any libraries that use thread pools should be configured to match
# the maximum value specified for Puma. Default is set to 5 threads for minimum
# and maximum; this matches the default thread size of Active Record.
#
max_threads_count = ENV.fetch("RAILS_MAX_THREADS") { 5 }
min_threads_count = ENV.fetch("RAILS_MIN_THREADS") { max_threads_count }
threads min_threads_count, max_threads_count

# Specifies the `port` that Puma will listen on to receive requests; default is 3000.
#
port        ENV.fetch("PORT") { 3000 }

# Specifies the `environment` that Puma will run in.
#
environment ENV.fetch("RAILS_ENV") { "development" }

# Specifies the `pidfile` that Puma will use.
pidfile ENV.fetch("PIDFILE") { "tmp/pids/server.pid" }

# Specifies the number of `workers` to boot in clustered mode.
# Workers are forked web server processes. If using threads and workers together
# the concurrency of the application would be max `threads` * `workers`.
# Workers do not work on JRuby or Windows (both of which do not support
# processes).
#
# MEMORY BUDGET: production is a 512 MB Heroku Basic dyno. Heroku raises R14 at
# 512 MB and kills the dyno at ~1 GB (R15), so aim to keep the whole dyno below
# 500 MB. Heroku sums the RSS of every process in the dyno, and each Ruby
# process running this app costs roughly 200-300 MB, so the number of
# processes is the main lever:
#
#   * Clustered mode with a single worker runs a master that holds a full copy
#     of the preloaded app next to the worker, and both are counted. That was
#     ~620 MB, permanently over quota.
#   * So 0 or 1 means single mode: one process, no master. Concurrency comes
#     from the threads (RAILS_MAX_THREADS), which are cheap compared to
#     processes.
#   * Two or more workers will not fit in 512 MB. Only raise WEB_CONCURRENCY
#     above 1 after moving to a bigger dyno, and check `heroku logs` for R14
#     afterwards.
#
web_concurrency = Integer(ENV.fetch("WEB_CONCURRENCY") { 0 })

# Puma reads WEB_CONCURRENCY itself, so single mode has to be set explicitly.
workers(web_concurrency > 1 ? web_concurrency : 0)

if web_concurrency > 1
  # Use the `preload_app!` method when specifying a `workers` number.
  # This directive tells Puma to first boot the application and load code
  # before forking the application. This takes advantage of Copy On Write
  # process behavior so workers use less memory.
  #
  preload_app!
end

# Allow puma to be restarted by `rails restart` command.
plugin :tmp_restart
