# 0001 — Simple village UI

**Date:** 2026-10-11
**Status:** accepted

## Decision

The UI uses one brand green, white cards on a soft grey-green page, a single
bundled font family (Mukta), and no decorative illustration. Turmeric marks
"needs your attention"; red is reserved for errors and emergency.

## Why

Two richer directions were tried the same day (a Paithani silk theme with
gold borders, then a Warli-painting theme with illustrated headers) and
rejected by the product owner as too busy for first-time smartphone users in
villages. What the target user needs is legibility on a dim, small screen and
an obvious next action, so hierarchy now comes from size, weight and position
rather than ornament.

## Consequences

- Fonts are bundled (`assets/fonts`), not fetched: works offline, and Marathi /
  Hindi render in the designed face instead of the system fallback.
- Home screens share one structure: `HomeHeader` (greeting, counters,
  language) then tiles then the day's list.
- Guided-tour spotlight is a white glow, so the highlighted control keeps its
  own colours.
