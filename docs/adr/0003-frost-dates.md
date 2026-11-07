# 3. Frost dates

Date: 2026-11-06

## Status

Accepted. The feature is experimental: everything it shows is an estimate, and it is new and might be flaky.

## Context

Gardeners want to know when the last frost of spring is likely, so they can plant out, and when the first frost of autumn is likely, so they can expect a crop to finish. Issue #5177 asks for this, and for past frosts to be shown on a planting.

There is no single worldwide dataset of frost dates. National sets exist for the US, Canada, the UK, New Zealand and China, with different thresholds and probability levels, and little for Australia. `WeatherReading` already holds daily weather for the 0.25 degree (about 25 km) ERA5 grid cell of each place with a planting, from Open-Meteo, so frost dates can be worked out the same way for anywhere.

ERA5 is a model smoothed over about 25 km. It can miss cold hollows and coastal effects, and the plan assumed it would run warmer than a real screen-level minimum.

## Decision

**Work frost dates out from the ERA5 daily minimum, for every grid cell**, with no latitude cutoff. National datasets may be added later as optional per-country sources where they are open-licensed and easy to load.

**Store results, not daily temperatures**, in two tables keyed by the grid cell as `WeatherReading` is, so a page reads one row and nothing is calculated as it loads:

- `frost_years`: one row per cell, threshold and frost year, with the first and last frost dates and the lowest minimum.
- `frost_stats`: one row per cell and threshold, with the status, years used, the median and percentile day numbers, and `computed_at`.

**`FrostCalculator` does the working out**, as a service with no database or network use, so it is tested on fixed series.

- A frost year is the calendar year in the Southern Hemisphere and July to June in the Northern, named for the calendar year it ends in. Day numbers count days into the frost year.
- A year is used only if it has a reading for every day, or nearly: `max_missing_days` allows a few gaps for station data. A missing day counts as not frosty.
- Per year: the first and last day at or below the threshold.
- Summary: the median first and last frost, the 90th percentile last frost as a safe-to-plant date, the 10th percentile first frost as an early warning, and the median frost-free days. Show a range, not one date.
- The frost-free period runs from the last frost of one frost year to the first frost of the next. This pairing is the same in both hemispheres.
- Status is `frost` when at least 70% of years have any frost, `possible` between 30% and 70%, `rare` below 30%, and `unknown` with no complete years. Rare cells show no dates. Frost-free days are given only for `frost`.
- The thresholds are 0 °C (frost) and 2 °C (frost danger, as members will see it), kept as constants on `FrostCalculator` so they can change without a migration. The 30% and 70% cut-offs are starting points to tune.

**Thirty years of history** for the central dates, from `temperature_2m_min` only. One variable counts at Open-Meteo's base rate, which is about 780 calls per cell by the cost model in `WeatherUpdater`. Where a cell already has `temp_min_c` readings, those dates are not fetched again. A longer record (back to 1940) is kept for the warming trend only, because older decades describe a cooler climate. These call figures are estimates from the code, not measured against Open-Meteo billing.

**Fill the tables from a daily rake task**, as `weather:update` does, because the app has no job runner. It handles cells that have an active planting but no `frost_stats` row, busiest first, within a call budget shared with `WeatherUpdater`, with current weather first. Gardens without a planting wait until plantings are covered. A page shows nothing for a cell until its row exists.

**Everything shown is labelled** approximate, regional and "Experimental · new and might be flaky", with a link to a short explanation that says the dates come from 25 km model data and to check a national weather service. Any text shown to members goes through I18n, with keys in all the locale files.

**Hardiness is kept on seeds and crops**, as `tender`, `half_hardy`, `hardy` or `unknown`, because a frost date means nothing until it is set against what a plant tolerates.

- `seeds.hardiness` records what the packet says, in the grower's entry, like `gmo` and `heirloom`.
- `crops.hardiness` is the level most packets of the crop and its varieties give, a tie going to the more tender one, else `unknown`. `crops.hardiness_source` says which (`seed_packets` or `manual`). A value set by hand is never overwritten.
- **EcoCrop is not used for hardiness.** Its killing temperature (`ktmp`) was tried and dropped. On 2026-11-06 it was blank for 25 of the 40 most-planted crops in the dev data, including tomato, cucumber, cabbage and kale. Of the 1,157 records that had a figure, 580 were -1 and 389 were 0, which looks like a default. It labelled pea, dill and parsley tender, and they are hardy in the garden. A wrong label shown as data is worse than none.
- Hardiness words are not tied to temperatures. Suppliers use them loosely, and there is no source we trust to map them.
- A planting uses its seed's hardiness if the packet gives one, otherwise its crop's. That is not built yet. Crop wranglers cannot yet set a `manual` value.

**Not decided yet:** how hardiness combines with frost dates for planting advice, member frost reports, the warming trend, ENSO, and frost alerts. These are in `docs/frost-dates-plan.md` as later phases.

## Validation

Computed for 1995 to 2024 from ERA5 and from GHCN-Daily station minimums, with up to 10 missing days allowed per station year, on 2026-11-06:

| Place | Frost days a year, station / ERA5 | Median last frost | Median first frost |
|---|---|---|---|
| Minneapolis | 145 / 145 | 2 days off | 6 days later |
| Salt Lake City | 111 / 128 | 5 days later | same |
| Boise | 106 / 110 | 11 days earlier | 5 days later |
| Anchorage | 186 / 194 | 2 days later | 6 days later |
| Melbourne Airport | 0.9 / 0.8 | 3 days earlier | same |
| San Francisco | rare / rare | | |

London Heathrow and Wellington had almost no TMIN in GHCN-Daily, so they could not be compared.

- Median dates agree within about a week at most sites. Boise's last frost is 11 days out.
- ERA5 does not run warm. Where it differs from the stations it shows the same or more frost, so there is no warm-bias correction.
- All the stations are airports, and none is a garden-scale cold hollow.
- The proposed pass mark, median dates within about a week and frost-day counts within about 20 percent, is a proposal, not a measured standard. Salt Lake City's frost-day count is 16% over.

## Consequences

- Dates are regional estimates, not a garden's own. A cold hollow or a sheltered wall can differ by weeks.
- A cell shows nothing until the rake task has reached it. At 30 years and about 780 calls a cell, covering the 121 cells with active plantings (the figure in #5177) takes weeks of the shared daily budget.
- The count of cells is a snapshot and grows with gardens. The call figures need checking against real Open-Meteo usage.
- Places with little frost show `rare` or `possible` and few or no dates, by design.
- The thresholds and cut-offs can change without a migration, but stored `frost_stats` must then be recomputed.
- Hardiness thresholds are unsettled, so frost dates are not yet turned into planting advice. The experimental label stays until validation passes against independent data and the thresholds are agreed with growers.
- Possible next steps: validate against more stations, including the southern hemisphere and sites without airport exposure, with a different source for the UK and New Zealand; a finer model (ERA5-Land or CERRA) if the bias matters; elevation downscaling for gardens with a known height; and member frost reports as local ground truth.
