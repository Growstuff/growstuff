The format for these crop seed files is CSV, with no header row, and the fields:

Crop name
English Wikipedia URL
Parent crop name (optional; the parent must be in an earlier row or file)
Scientific name (optional; taken from the parent if left out)

Files are loaded in name order by `rake db:seed` (see `load_crops` in `db/seeds.rb`),
and loading one again just updates the crops that are already there.

`crops-20-growstuff-org.csv` is the set of crops on https://www.growstuff.org, from
https://www.growstuff.org/crops.csv, with parents ahead of their children.
