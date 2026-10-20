## Crop search

Crop search runs in Postgres, in `SearchCrops` ([app/models/concerns/search_crops.rb](app/models/concerns/search_crops.rb)),
and is used through `CropSearchService`. There is no separate search server or
index to keep in sync.

A crop matches when a word of its name, an alternate name or a scientific name
starts with the search term, or when one of those names is similar to it
(`pg_trgm`'s `word_similarity`), which forgives typos and plurals. Matching
ignores case and accents (`unaccent`). Results are ranked by how well the name
matched (the crop's own name counts for more than alternate or scientific
names), then by how many plantings the crop has, and for a signed in member,
by how many times they have planted it.

Both extensions are enabled by a migration, so `db:schema:load` is all a new
database needs.
