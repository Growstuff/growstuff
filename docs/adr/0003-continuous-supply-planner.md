# 3. Continuous supply planner

Date: 2026-11-06

## Status

Proposed

(Numbered 3 on the assumption that ADR 0002, harvest predictions, has merged
first. Renumber if not.) Tracked in issue #5309.

## Context

ADR 0002 predicts, for a planting that exists, the day its first harvest will
arrive, from the garden's weather and the crop's heat needs. A grower usually
asks the opposite question: "I want 4 lettuces a week from October to March.
How many do I plant, and when?"

Commercial planners answer it by working backwards from the harvest date. For a
home or market gardener it is the main reason to plan at all, because
succession sowing is the thing people get wrong: they sow everything at once and
have a glut, then nothing.

Why the answer is not "sow every week":

- A crop needs a roughly fixed amount of heat to reach harvest (see 0002).
  Heat arrives slowly in cool weather and quickly in warm weather.
- Let `H(s)` be the harvest day for a sowing on day `s`. In **autumn**, as it
  cools, each later sowing takes longer, so `H` advances by more than a day per
  day of delay. Sowings a week apart are harvested more than a week apart, and
  to harvest every week the grower must sow **more often than weekly**: some
  weeks two sowings.
- In **spring**, as it warms, later sowings catch up. Sowings a week apart are
  harvested less than a week apart, so harvests bunch, and to harvest every
  week the grower must **skip** some sowing weeks.
- In midsummer or midwinter the relation is near one-to-one: steady weekly
  sowing.

The data is already here: `WeatherReading` (daily temperatures per 0.25° grid
cell), `EcocropData` through `Crop#ecocrop_heat_data` (base temperature, heat
target, growing cycle, with parent inheritance), `GrowingDegreeDays`, garden
latitude and longitude, and `Planting`/`Job` for recording the result.
`Crop#harvest_style` (`single` or `repeated`, from the crop harvest style
change) says which crops the planner is for.

"Ready by a target date" (a wedding, a market day) is the special case of one
harvest week, and falls out of the same calculation.

## Decision

Build a planner that, given a crop, a garden and a wanted weekly supply, returns
a dated sowing schedule, computed by walking the heat model **backwards** from
each wanted harvest week.

### Scope of v1

- Crops whose `harvest_style` is `single`: each plant is harvested **once**
  (lettuce, radish, spinach, bok choy, carrots, beetroot, many herbs treated as
  cut-once). Crops that crop for weeks (`repeated`: tomato, beans, courgette)
  need a different model (supply per plant over a window) and are out of scope.
  The planner says so for them.
- Supply is counted in **plants** (heads, roots), not weight. Members already
  count `Planting#quantity`. No yield-per-plant figure is needed.
- The result is **advice**: shown on a page, with a button to add the sowings
  as planned plantings. It never changes the member's data without their action.
- Annual, non-nursery use in a garden with a location. A garden without a
  location asks for one.

### Inputs

| Input | Default | Notes |
| --- | --- | --- |
| `crop` | required | Must have `ecocrop_heat_data` and a `single` harvest style (see below). |
| `garden` | required | Gives latitude, longitude and the weather cell. |
| `per_week` | required | Plants wanted harvested each week. |
| `from`, `to` | next Monday, 26 weeks later | The harvest weeks wanted. |
| `loss` | 0.15 | Share of plants that won't reach harvest. Sow `ceil(per_week / (1 - loss))`. |
| `harvest_window_days` | derived, see below | How long a plant stays good once ready. |
| `sowing_day` | none | Optional weekday to snap sowings to (for example Saturday). |

### Algorithm

All in plain Ruby objects under `app/services/supply_planner/`, no persistence.

1. **Climate for the garden.** Build one daily series of `(tmax, tmin, soil_temp)`
   for each day of the planning period, used for days that have not happened yet.
   - Days up to today: the observed `WeatherReading`s for the cell.
   - Days ahead: the **average of the same calendar day over every year we have
     (up to the last 5)**, falling back to the single prior year, as 0002 does.
     Averaging smooths the lumpy prior-year weather and is the main accuracy
     gain over 0002 for a planner that looks months ahead.
   - Also return the spread (earliest and latest year's result) so we can show
     a range. Not required for v1 (see Phases).
   - Leap day: fold 29 Feb into 28 Feb.
2. **Heat per day.** `GrowingDegreeDays.new(base:).for_day(reading)` as now.
3. **Walk back.** For a wanted harvest day `h`, find the **latest sow day `s`**
   such that the heat from `s` to `h` is at least `target`
   (`ecocrop_data.first_harvest_degree_days`). Add to `GrowingDegreeDays`:

   ```ruby
   # The latest day to start from so the heat up to end_on reaches target.
   # readings are the days up to end_on. Nil if they never add up.
   def date_starting(target, readings, end_on)
   ```

   It sums `for_day` from `end_on` backwards and returns the day the total
   reaches `target`. It must be the exact mirror of `date_reaching` (same
   rounding and inclusive-day rules) and have a property spec: walking forward
   from the result reaches the target on or before `end_on`, and from the day
   after it does not.
4. **One harvest per plant, over a window.** A plant sown on `s` is ready on
   `H(s)` and stays harvestable for `harvest_window_days`, the days from ready to
   past it (bolting, going woody). Derive it as
   `median_days_to_last_harvest - median_days_to_first_harvest` for the crop,
   clamped to 7..28 days, defaulting to 10 when either is missing. To make a
   week's supply, sow for the **end** of the week's window, so the plants are
   ready by the week and the first of them is not waiting long. v1 uses the
   simple rule: target the **start** of each wanted week as `h`, and sow
   `per_week` there. The window is used only for the gap-fill and the warnings
   below. Revisit once members report what they see.
5. **Make the schedule.** For each wanted week `w` from `from` to `to`:
   `h = w.beginning_of_week`, `s = date_starting(...)`, `plants = ceil(per_week
   / (1 - loss))`. Result: a `Sowing(sow_on:, plants:, harvest_week:)`.
6. **Group by sowing week.** Group sowings by the calendar week of `sow_on`.
   - Two harvest weeks landing in one sowing week: a **double** week. Show one
     line with the total plants, and the two harvest weeks it serves.
   - A sowing week with none between two with some: a **skip** week.
   - Optionally snap each group to `sowing_day` (see below).
7. **Snap to a routine day.** With `sowing_day`, move each sowing **earlier** to
   the nearest such weekday (earlier so the crop is not late), and recompute the
   harvest day it now gives, flagging any harvest week that is now missed or
   doubled. Never move later.
8. **Constraints.** Applied per sowing, each producing a `Warning` on the entry,
   not a hidden change, so the grower sees the limit:
   - **Frost.** Compute the last spring and first autumn frost from
     `temp_min_c <= 0` in the cell's history (median across years). Warn if the
     plant would be in the ground, as seedling or mature plant, in a frost,
     unless the crop is frost tolerant (EcoCrop `ktmp`/`tmin` below 0 later; v1
     uses only the crop's `tmin` as a proxy and warns below it).
   - **Germination.** Warn if the sowing day's soil temperature (or air mean
     where soil is missing) is below the crop's minimum germination temperature.
     EcoCrop has no such field. v1 uses `tmin` (base) as the floor. Replace
     with a seed packet soil temperature attribute when it exists (see
     Consequences).
   - **Too hot.** Warn if the mean of `temp_max_c` over the last quarter of the
     growth period exceeds `topmx`. This is the bolting risk for lettuce.
   - **Sowing months.** If `crop.median_sow_months` is present and the sowing
     month isn't in it, warn ("members rarely sow this in this month"). Do not
     block.
   - **Heat never adds up.** If the heat never reaches the target before the
     wanted day, say that harvest week can't be met and leave it out.
   - **Day length.** GDD ignores it, and a long day can make a crop bolt. Say
     so in the page's explanation. Not modelled.
9. **Existing plantings (gap-fill, phase 2).** Count the garden's current
   plantings of the crop (not finished or failed). Each contributes
   `quantity * (1 - loss)` plants, starting from
   `first_harvest_predicted_at` and spread across `harvest_window_days`. Subtract
   them from each week's `per_week` before computing sowings, so the plan tops up
   what is already in the ground and a member who re-runs the planner doesn't
   double-plant. Planted dates in the future (`Planting#planned?`) count the same
   way, which is how a saved plan avoids being planned twice.
10. **Target-date special case.** `SupplyPlanner.new(..., from: date, to: date,
    per_week: n)` for one week is "ready by". The page offers it as a
    "I need this ready by [date]" field with the answer "sow by [date]", showing
    the range from the earliest and latest years when phase 3 is done.

### Result objects

```ruby
module SupplyPlanner
  Result  = Struct.new(:sowings, :warnings, keyword_init: true)
  Sowing  = Struct.new(:sow_on, :plants, :harvest_weeks, :kind, :warnings, keyword_init: true)
  # kind: :regular, :double, :make_up (gap-fill)
end
```

`Result` also exposes `skipped_weeks` (sowing weeks with none) for the page.
Everything is a value object so the controller and views never recompute.

### Structure and conventions

- `app/services/supply_planner.rb`: the entry point; `SupplyPlanner.new(crop:,
  garden:, per_week:, from:, to:, loss:, sowing_day:, today:).call` returns a
  `Result`. `today:` is injectable, as in `CropJobSchedule`.
- `app/services/supply_planner/climate.rb`: the day-by-day series (step 1).
- `app/services/supply_planner/constraints.rb`: the warnings (step 8), one small
  method per constraint so each is specced alone.
- `app/services/growing_degree_days.rb`: gains `date_starting`.
- `app/models/concerns/plan_supply.rb` is **not** needed. Keep the planner out
  of `Crop` and `Planting`.
- Reuse `Crop#ecocrop_heat_data`, `EcocropData#first_harvest_degree_days`,
  `Crop#effective_harvest_style`, `Garden` latitude/longitude,
  `WeatherReading.grid_point/at/between`. Do not duplicate cell lookup; add
  `Garden#weather_cell_readings` only if it doesn't already exist beside
  `Planting#weather_cell_readings` (extract, don't copy).
- Rails conventions, DRY, betterspecs as AGENTS.md says. Rubocop clean. No new
  gems.

### Which crops are single-harvest

`Crop#harvest_style` is `single` or `repeated`, null when unknown, and a variety
follows its parent through `Crop#effective_harvest_style`. It is set by crop
wranglers and by a one-off data task for the commonest crops. The planner
accepts `single` only. Null means "ask the member to confirm" on the page, with
a checkbox "I harvest the whole plant". No heuristic from the medians is used:
without enough harvest logs they are nil, and a crop picked young looks
repeated.

### UI (phase 2)

- `PlantingPlansController` (RESTful, `index`/`new`/`create`; no `show`, nothing
  stored in v1) or `Crops::SupplyPlansController#new`/`#create` nested under the
  crop. Choose nested under the crop: members arrive from a crop page ("Plan a
  supply of lettuce"). Route: `resources :crops do resource :supply_plan, only:
  %i(new create) end`.
- Form: garden (default: the member's first garden with a location), plants per
  week, from/to, loss, optional routine sowing day, optional "ready by" date.
- Result page: a table with one row per sowing week: *week of*, *sow*, *harvest
  weeks served*, notes. Doubles and skips are marked in words ("sow double this
  week, because it's cooling and each batch takes longer than the last"), not by
  colour alone. A calendar of the sowing and harvest weeks, and optionally a
  small line chart of sowing date against harvest date.
- "Add these as plans" button: creates `Planting`s with future `planted_at`
  (so `planned?`), quantity, garden and crop, for the chosen rows, after the
  member ticks them. Each sowing day also becomes a job through
  `AddCropJobs`/`ApplyCropJobTemplate` as for any planned planting, so it shows
  in the member's jobs list and calendar feed. Idempotent: a second submit makes
  no duplicates (match crop, garden, planted_at).
- Copy and layout follow the existing design decisions in the app; keep to the
  site's brief, plain wording (Celsius, metric, NZ/US spelling as the rest of the
  UI uses it).
- Accessible tables, labels on every field, no colour-only meaning.
- No JavaScript framework needed; a plain form posting to `create`.

### Phased plan

**Phase 0: check the data (before any code).** On production, with
`heroku run -a growstuff-prod rails runner`:
1. How many cells have at least 3 years of readings for each of the days
   needed? `WeatherUpdater` only back-fills cells that have a tracked planting,
   within a daily budget, so history may be thin. This decides whether step 1
   averages years or falls back to one.
2. For the 20 most planted single-harvest crops, compare the heat-based days to
   first harvest with the crop's median days (see the offered comparison in the
   0002 follow-ups). If they disagree widely for a crop, the planner is wrong
   for it, and we need a per-crop correction or to exclude it.
3. How many members have a garden with a location and a lettuce planting?
   (Rough size of the audience.)

**Phase 1: the calculation, no UI.**
- `GrowingDegreeDays#date_starting` and its specs.
- `SupplyPlanner::Climate`, `SupplyPlanner`, `SupplyPlanner::Constraints`,
  value objects, with specs for regular, double and skip weeks.

**Phase 2: the page and saving.**
- Controller, routes, form, result view, i18n, "add as plans".
- Gap-fill against existing plantings (step 9).
- Link from the crop page and the garden page.

**Phase 3: confidence.**
- Range from the earliest and latest years, shown as "sow between X and Y".
- Re-plan: if a planned planting's sow date has passed or the weather differs,
  show how the remaining weeks shift, and move the jobs not yet done with them.
- Job reminders ("sow the next batch Saturday") from planned plantings through
  `JobIdeas`.
- Per-week yield (weight) once `harvests` data supports it.

### File-by-file task list

1. `app/services/growing_degree_days.rb`: add `date_starting`.
2. `spec/services/growing_degree_days_spec.rb`: forward/backward round trip,
   target never reached returns nil, missing temps count as zero.
3. `app/services/supply_planner.rb`, `supply_planner/climate.rb`,
   `supply_planner/constraints.rb`.
4. `spec/services/supply_planner_spec.rb`, `.../climate_spec.rb`,
   `.../constraints_spec.rb`.
5. `spec/support/shared_contexts/`: a shared context that builds a year of
   weather for a garden (a cooling autumn and a warming spring, 5 years) next to
   `heat_predicted_planting.rb`; extract the common crop/EcoCrop setup from that
   file rather than copying it.
6. `config/routes.rb`, `app/controllers/crops/supply_plans_controller.rb`,
   `app/views/crops/supply_plans/{new,create}.html.haml` (match the app's view
   language), `config/locales/en.yml`, a request/feature spec, an accessibility
   check as the app's other pages have.
7. `app/models/planting.rb`: nothing, unless gap-fill needs a scope: add
   `Planting.of(crop, garden)` only if one doesn't exist.
8. Docs: update this ADR's status to Accepted when phase 1 merges; note changes in
   `docs/` if there is a user guide.

### Specs to write (betterspecs: one expectation, descriptive contexts)

- `date_starting`: round trip with `date_reaching`; cold run never reaches.
- Climate: observed days win over averages; a missing year falls back; leap day.
- A warming spring (each later sow ready sooner): 8 weekly harvests need fewer
  than 8 sowings, with a skipped week.
- A cooling autumn: 8 weekly harvests need more than 8 sowings, with a double
  week.
- Midsummer, near-constant temperature: one sowing a week.
- `loss: 0.2`, `per_week: 4`: plants is 5 per sowing.
- `sowing_day`: snaps earlier and never later; flags a missed week.
- Constraints: each warning raised and not raised.
- Existing plantings reduce the plants needed; finished and failed ones don't.
- Heat never reaching the target: that week is left out with a message.
- Garden with no location, crop with no heat data, crop not `single`: each
  explains itself.
- "Add as plans" creates planned plantings and jobs once, not twice.

Specs for time-dependent code pass `today:` rather than freezing time.

## Consequences

- Members get an answer to the question they actually have, using data we
  already collect. It is the first feature built on the weather history beyond
  display.
- **The plan is only as good as the crop's heat figures.** EcoCrop's `gmin` is
  the shortest cycle to a full crop, so a baby-leaf lettuce is ready earlier
  than planned. The planner errs late, which means a surplus, not a gap.
- **Weather history is the weak point.** `WeatherUpdater` backfills only cells
  with tracked plantings and only within its daily budget, so a new place may
  have a few months, not years. Phase 0 measures this. With one year the
  planner behaves like 0002 stretched across six months, and says so on the page.
  A new place can be backfilled by an on-demand job when a member opens the
  planner for a garden whose cell lacks history (costs Open-Meteo calls; share
  the existing budget).
- Heat ignores day length, frost damage, and germination. The warnings cover
  some of it. Plans for the shoulder seasons deserve a caveat, shown on the page.
- Counting plants, not weight, means "4 lettuces a week", not "1 kg". Good for
  the crops in scope.
- Single-harvest only. A tomato grower gets "this planner is for crops you pick
  once". A model for continuous croppers is a separate decision.
- The planner depends on `harvest_style` being filled in, which needs curation,
  and is a place where members' logs and wranglers' data may disagree. Null
  falls back to asking.
- The licence of the CGIAR copy of EcoCrop is unconfirmed (see 0002). The
  planner reads heat data only through `Crop#ecocrop_heat_data`, so dropping it
  disables the planner and breaks nothing else.
- Open-Meteo data is CC BY 4.0: the planner page should carry the attribution
  already used with weather charts.
- Not storing plans keeps v1 small, but a member can't come back to "my
  lettuce plan". Saving as planned plantings is the persistence. A named,
  re-runnable plan record can follow if members ask.

## Open decisions for the maintainer

1. **Plants or bed space.** v1 counts plants. Counting by bed area would use
   `Garden` area and layout (`grid_rows`, `grid_columns`, `layout_features`,
   `Plant#bed_x/bed_y`, `Crop#default_diameter`) to say whether the sowings
   fit. Recommend plants first, and bed capacity as a phase 3 warning.
2. **Gap-fill or standalone.** Recommend gap-fill in phase 2, standalone in
   phase 1.
3. **Display or create plantings.** Recommend both: display first, "add as
   plans" in phase 2.
4. **Where it lives.** Recommend nested under the crop, with a link from the
   garden. Alternative: a planner page on the dashboard.
5. **Seeding `harvest_style`.** Recommend a one-off task for the 50 most planted
   crops, then wranglers.
6. **Seedlings vs direct sowing.** v1 treats the date as the day it goes in the
   ground and doesn't model nursery time. A template step already exists for
   hardening off. A crop sown in trays 3 weeks earlier is told "plant out on
   X"; a later change could subtract a per-crop nursery period.
7. **How wrong is acceptable.** If phase 0 shows the heat date and the median
   disagree by more than a week for many crops, hold the UI.

## Notes for implementation

- Start with Phase 0 and report the numbers before building. It may change
  what to build.
- `GrowingDegreeDays` is the only place the heat arithmetic lives. The planner
  calls it and doesn't recompute.
- Keep every calculation in services and value objects with no `Time.now`:
  pass `today:`.
- Specs for Rails could not be run in the author's sandbox (Ruby version), so
  run the full suite and rubocop before opening the PR.
