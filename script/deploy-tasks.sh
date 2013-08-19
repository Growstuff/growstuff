#!/bin/bash

# tasks to run at deploy time, usually after 'rake db:migrate'

# When adding tasks, do so in chronological order, and note the date
# when it was added.  This will help us know which ones have been run
# and can safely be commented out or removed.

echo "2013-08-18 - reset crop planting counts"
rake growstuff:oneoff:reset_crop_plantings_count
