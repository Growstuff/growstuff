#!/bin/bash

# tasks to run at deploy time, usually after 'rake db:migrate'

# When adding tasks, do so in chronological order, and note the date
# when it was added.  This will help us know which ones have been run
# and can safely be commented out or removed.

# Default format is:
# echo "YYYY-MM-DD - do something or other"
# rake growstuff:oneoff:something

echo "2013-07-18 - zero crop plantings_count"
rake growstuff:oneoff:zero_plantings_count

echo "2014-08-10 - replace ping with pint in db"
rake growstuff:oneoff:ping_to_pint
