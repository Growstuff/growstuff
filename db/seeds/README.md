The format for these crop seed files is CSV, with no header row, and the fields:

Crop name
English Wikipedia URL
Parent crop name (optional; the parent must be in an earlier row or file)
Scientific name (optional; taken from the parent if left out)

Files are loaded in name order by `rake db:seed` (see `load_crops` in `db/seeds.rb`),
and loading one again just updates the crops that are already there.

`crops-20-growstuff-org.csv` is the set of crops on https://www.growstuff.org, from
https://www.growstuff.org/crops.csv, with parents ahead of their children.

## Crop job templates

`crop_job_templates/*.json` has a crop's suggested jobs, one file per crop. They are
added by `rake db:seed`, or on their own by `rake growstuff:import_crop_job_templates`
(with `file=path.json` for just one). Templates are only ever added: one already there,
by crop and name, is left alone, so a crop wrangler's changes survive seeding again.
Templates are written as `draft`, for a crop wrangler to check and publish.

```json
{
  "crop": "tomato",
  "templates": [
    {
      "name": "Growing tomatoes",
      "applies_to": "cherry tomato",
      "season": "any",
      "status": "draft",
      "steps": [
        {"name": "Sow seeds indoors", "amount": 6, "unit": "weeks", "direction": "before", "anchor": "planting_out", "repeat": "once"}
      ]
    }
  ]
}
```

- `crop`: the crop's name. A crop that isn't in the database is skipped.
- `applies_to` (optional): the name of one of that crop's varieties, for a template that is only for it.
- `season`: `any`, `spring_summer` or `autumn_winter`.
- `status`: `draft` or `published`.
- A step's `unit` is `days`, `weeks` or `months`; `direction` is `before` or `after`; `anchor` is
  `sowing`, `planting_out` or `first_harvest`; `repeat` is `once`, `weekly`, `fortnightly` or `monthly`.
  Leave out what you don't need: `amount` is 0, `unit` weeks, `direction` after, `anchor` planting_out
  and `repeat` once. A step can also have an `external_uri`: a web address (starting with `http://` or
  `https://`) with more on how to do it.
- Steps keep the order written.
