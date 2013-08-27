#!/bin/bash

# tasks to run at deploy time, usually after 'rake db:migrate'

# When adding tasks, do so in chronological order, and note the date
# when it was added.  This will help us know which ones have been run
# and can safely be commented out or removed.

# Default format is:
# echo "YYYY-MM-DD - do something or other"
# rake growstuff:oneoff:something

echo "2013-08-26 - set planting owner"
rake growstuff:oneoff:set_planting_owner

echo "2013-08-26 - initialize member planting count"
rake growstuff:oneoff:initialize_member_planting_count
