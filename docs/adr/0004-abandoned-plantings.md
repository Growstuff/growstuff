# 4. Abandoned plantings

Date: 2026-11-11

## Status

Accepted. It only changes what the weather and frost sections of a planting show, and what the weather updater collects.

## Context

Nothing marks a planting as finished except its owner. A planting that was put in and forgotten stays "growing" for ever. One in production was planted in 2013 and has never been finished.

That is wrong for the weather features in three ways:

- The planting page shows the last year of its life to date, so a planting abandoned years ago shows this year's weather, which it did not grow through.
- The weather updater keeps collecting current weather for it every day, and a year of last year's weather to expect.
- The climate notes judged it by the weather of the last year, so a planting that died long ago was told it was too hot or too cold now.

We can say when a planting should have finished. `Planting#weather_due_on` is its planting date plus its expected lifespan: the crop's median lifespan, or its parent's, or failing those the median days to the crop's last harvest (annuals only), or the middle of EcoCrop's crop cycle.

## Decision

**A planting is abandoned when it is not finished, not failed, and more than a year past its due day.** `Planting#abandoned?` works this out when asked and nothing is stored, so it needs no migration and changes by itself if the crop's figures change.

- The year is `Planting::ABANDONED_AFTER_DAYS` (365). A year is long enough that a slow crop, or a late harvest, is not called abandoned, and short enough that nobody is shown the wrong year's weather for long. It is a starting point to tune.
- With no due day we can't tell a long-lived planting from an abandoned one, so `abandoned?` is false.

**An abandoned planting is treated as finished on its due day**, for the weather and frost sections only:

- `weather_last_day` is the due day, so the chart and the readings cover its own life, up to a year ending then, and not the last year to date.
- It expects no more weather: there is nothing ahead to project.
- The weather updater gives it a stretch of history ending on its due day, with no year before it started, the same as a planting that finished then. It no longer asks for current weather.
- The frost section judges it as a finished planting that ended on its due day.
- The weather section says that nobody marked it finished and that the weather shown ends on its due day.

**Nothing is changed on the planting itself**, and it still counts as growing everywhere else (the progress bar, lists, jobs and so on). Those would need their own decision.

## Consequences

- An abandoned planting no longer costs a daily fetch of current weather, only the history of its life, once.
- `Planting.weather_tracked`, the SQL scope the updater and the "loading" message use, does not know about abandoned plantings, because the due day is worked out in Ruby from the crop. Abandoned plantings are still included, and the updater gives them a historic stretch. If there turn out to be many, the scope can be narrowed.
- `abandoned?` builds on `weather_due_on`, which was written for the weather. If other features want it, the due day should get a plainer name.
- The climate notes that compare the weather with the crop's EcoCrop temperatures judge the past only up to the due day, so a planting is not marked down for weather after it was expected to be done.

## Alternatives considered

- **Store it**, as a column set by a job. Rejected: a derived value is cheap, reversible and needs no job runner, which the app does not have.
- **Ask the owner** whether it is finished, and let them say. A good follow-up, since it fixes the record and not just the display, but it is separate work.
- **Judge by the owner's activity** (when they last harvested, photographed or edited it). It would catch plantings that are only a little overdue, but it needs more queries and is easily fooled by a member who is active but has forgotten one planting.
- **A shorter threshold.** Rejected for now: a perennial's lifespan estimate is rough, and the cost of calling a live planting abandoned is higher than the cost of showing an old one for a few more months.
