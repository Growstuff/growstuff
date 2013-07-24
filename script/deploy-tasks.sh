#!/bin/bash

# tasks to run at deploy time, usually after 'rake db:migrate'

# When adding tasks, do so in chronological order, and note the date
# when it was added.  This will help us know which ones have been run
# and can safely be commented out or removed.

echo "2013-07-23 - set seeds tradable to nowhere"
rake growstuff:oneoff:tradable_to_nowhere
