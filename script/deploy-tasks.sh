#!/bin/bash

# tasks to run at deploy time, usually after 'rake db:migrate'

# Permanent tasks
rails db:migrate
rails assets:precompile

# When adding tasks, do so in chronological order, and note the date
# when it was added.  This will help us know which ones have been run
# and can safely be commented out or removed.

# Default format is:
# echo "YYYY-MM-DD - do something or other"
# rake growstuff:oneoff:something

# One-off tasks

# echo "2015-01-30 - build Elasticsearch index"
# rake growstuff:oneoff:elasticsearch_create_index
