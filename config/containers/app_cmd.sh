#!/usr/bin/env bash

# Prefix `bundle` with `exec` so unicorn shuts down gracefully on SIGTERM (i.e. `docker stop`)
exec bundle exec rake db:create
exec bundle exec rake db:seed
exec bundle exec unicorn -c config/containers/unicorn.rb -E $RAILS_ENV;
