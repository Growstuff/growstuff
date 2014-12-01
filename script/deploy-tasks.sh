#!/bin/bash

# tasks to run at deploy time, usually after 'rake db:migrate'

# When adding tasks, do so in chronological order, and note the date
# when it was added.  This will help us know which ones have been run
# and can safely be commented out or removed.

# Default format is:
# echo "YYYY-MM-DD - do something or other"
# rake growstuff:oneoff:something

echo "2014-12-01 - load lots of new crops"
rake growstuff:import_crops file=db/seeds/crops-12-mint.csv
rake growstuff:import_crops file=db/seeds/crops-13-brassicas.csv
rake growstuff:import_crops file=db/seeds/crops-14-london-workingbee.csv
rake growstuff:import_crops file=db/seeds/crops-15-squashes.csv

echo "2014-12-01 - load alternate names for crops"
rake growstuff:oneoff:add_alternate_names
