# 1. World neighbours

Date: 2026-10-24

## Status

Accepted

## Context

Job suggestions include a "Near you" section: what gardeners within a set
distance of the member have been doing at this time of year. A fixed 25 km radius
often finds too few gardeners to show a trend, because a suggestion needs at
least `OthersJobs::MIN_GARDENERS` gardeners doing the same job.

Distance is a poor proxy for what matters when gardening: the season. The season
follows latitude and hemisphere. A gardener 5,000 km east or west at the same
latitude is sowing and harvesting at about the same time. A gardener 500 km
north can be several weeks behind, and one in the other hemisphere is in the
opposite season.

## Decision

A **world neighbour** is a confirmed member with a known location whose latitude
is within `JobIdeas::World::BAND` degrees (5) of the member's, on the same side
of the equator. Longitude and distance don't matter.

- The member's own jobs are left out, as are those of members they have blocked.
- World neighbours are their own section, "World neighbours", with their own
  switch (`world`), separate from "Near you".
- It suggests the jobs world neighbours finished in the three weeks either side
  of today's date in this year and each of the five before, plus the last two
  weeks, when enough of them did the same one. This year is included, unlike
  the other sources, so what neighbours are doing now counts.
- "Near you" stays about place. It widens its radius (25, 50, 100, 250, 500 km)
  until there are `JobIdeas::Nearby::ENOUGH` gardeners, so a sparse area still
  finds neighbours.

## Consequences

- Members in sparsely populated places get suggestions from gardeners who
  share their season.
- Nearby gardeners can appear in both sections. Ideas have a key per source, so
  hiding one doesn't hide the other.
- The band is in degrees of latitude, so it covers the same number of kilometres
  north to south everywhere, but sits closer to the poles where climate changes
  faster with latitude. Altitude, coast and local climate aren't considered.
- Members whose latitude is within `BAND` degrees of the equator only see
  neighbours on their own side of it, even though the seasons there are less
  distinct.
