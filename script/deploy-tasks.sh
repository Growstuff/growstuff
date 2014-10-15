#!/bin/bash

# tasks to run at deploy time, usually after 'rake db:migrate'

# When adding tasks, do so in chronological order, and note the date
# when it was added.  This will help us know which ones have been run
# and can safely be commented out or removed.

# Default format is:
# echo "YYYY-MM-DD - do something or other"
# rake growstuff:oneoff:something

echo "2014-09-28 - upload tomatoes"
rake growstuff:import_crops file=db/seeds/crops-11-tomatoes.csv

echo "2014-10-02 - remove unused photos"
rake growstuff:oneoff:remove_unused_photos

echo "2014-10-05 - generate crops_posts records for existing posts"
rake growstuff:oneoff:generate_crops_posts_records
