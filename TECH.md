## Crop search

Crop search runs in Postgres, in `SearchCrops` ([app/models/concerns/search_crops.rb](app/models/concerns/search_crops.rb)),
and is used through `CropSearchService`. There is no separate search server or
index to keep in sync. See the comment at the top of that file for how names
are matched and ranked.
