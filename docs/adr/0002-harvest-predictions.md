# 2. Harvest predictions

Date: 2026-11-06

## Status

Accepted

## Context

Growstuff says when to expect a harvest: on the planting timeline, in the
dashboard, in job suggestions, in reminder emails and the calendar feed, and in
the checks that decide whether a planting is ready to harvest. All of it came
from one figure for the crop: the median days from planting to first harvest, of
the plantings where a member logged a harvest.

That figure ignores the season and the garden's climate, so a lettuce planted in
spring and one planted in autumn got the same date. It is also built on thin
data, because few members log harvests, and there are too few plantings of most
crops near any one garden to take a local median.

A crop needs about the same total warmth to reach harvest wherever it grows. That
is measured in growing degree days (GDD): each day counts how far its average
temperature is above the crop's base temperature, below which it barely grows.
A crop needing 600 GDD takes 50 days in summer and 90 in autumn.

The data to work this out was already here: `WeatherReading` holds daily
temperatures for each garden's grid cell, and `EcocropData` holds temperature
and growing cycle figures for crops, matched by scientific name.

## Decision

Predictions are made per planting, by `PredictHarvest` and `PredictPlanting`.

**First harvest, `first_harvest_predicted_at`**, is the first of these that can
be worked out:

1. **Heat.** The crop has EcoCrop figures (its own, or else its parent's, and so
   on up) and the garden has a location. The base temperature is `tmin`. The heat
   a first harvest needs is the shortest growing cycle (`gmin`) at the optimal
   temperature (the middle of `topmn` and `topmx`) above the base. The garden's
   GDD are added up from the planting day, using its observed weather and then
   last year's weather moved forward a year for the days ahead, up to `gmax` days
   after planting. The prediction is the day the total reaches the target. It is
   cached for 8 hours.
   If that day comes after the planting is expected to have finished (planting
   day plus the crop's median lifespan), the heat figures don't fit how the crop
   is usually grown, and the prediction falls through to the median. The
   lifespan is never changed to suit the heat.
2. **Median.** `planted_at` plus the crop's median days to first harvest.
3. Otherwise there is no prediction.

**One source for a planting.** Anything about a particular planting that needs to
know when its first harvest is expected asks the planting
(`first_harvest_predicted_at`, or `predicted_days_to_first_harvest` for the days
from planting). It does not read the crop's median directly. This keeps the
timeline, the ready state, the dashboard, job suggestions, jobs made from a crop
job template, reminder emails and the calendar feed saying the same thing.

A planting with a logged harvest needs no prediction: it is ready to harvest,
and `update_harvest_days!` records the real days, which feed the crop's median.

**Crop-level places keep the median.** Crop pages, the API, the sowing
suggestions, and a crop job template previewed or applied for a planting day with
no planting have no garden or weather to use, so they show the crop's typical
figure.

**Heat is used for the first harvest only.** Growing degree days say when a crop
is ready to start being harvested. They are not used for how long a planting
lives. The last harvest (`last_harvest_predicted_at`, from the median days to
last harvest) and the finish date (`finish_predicted_at`, from the median
lifespan, or the parent's) still use medians, as do everything built on the
lifespan: `expected_lifespan`, `percentage_grown`, `late?`, `super_late?` and
`progress_state`. How long a crop keeps producing depends on more than warmth,
and EcoCrop has nothing to say about it. `gmax` only limits how far ahead the
first-harvest search looks; it is not a lifespan.

A planting can therefore be ready to harvest by its heat date while its progress
bar, which follows the median lifespan, is not yet full.

## Consequences

- Predictions follow the season and the place, and firm up as the real weather
  replaces last year's.
- Coverage depends on EcoCrop. On production on 2026-11-05, 1,004 of 1,401 crops
  (72%) had figures once parents were counted, including 44 of the 50
  most-planted. The rest use the median.
- A garden with no location, or no weather for it, uses the median, as does a
  planting whose heat never reaches the target within `gmax` days.
- `gmin` is the cycle to a full crop, so a crop picked young (baby leaves, spring
  onions) may be ready sooner than predicted.
- Predictions rely on the weather ahead being like last year's, and can be up to
  8 hours behind new readings. The first uncached prediction for a planting runs
  a few queries, so pages listing many plantings depend on the cache.
- The median fallback is only as good as members' harvest logging.
- The licence of the CGIAR copy of EcoCrop is unconfirmed. The heat figures come
  through `Crop#ecocrop_heat_data` alone, so dropping them leaves every caller
  working on the median.
- Possible next steps: fit a crop's base temperature and heat target from its own
  plantings once enough harvests are logged, use seed packet soil temperature or
  days to maturity as other sources, and predict the last harvest and finish date
  from heat.
