---
name: travel-search
description: |
  Search European train journeys (Trainline) and Airbnb stays as callable
  building blocks. Use when the user wants train times between two cities/
  stations (with every calling point / stop of the train, not just the
  origin-destination pair), or wants to search or inspect an Airbnb listing
  (price, availability calendar, host, reviews summary). Drives published
  @reduck scripts: thetrainline.com/search_journeys, airbnb.com/search_listings,
  airbnb.com/get_listing. NOT for: booking or paying for anything, non-Trainline
  rail markets (US/Asia), or other lodging platforms (Booking.com is not yet
  covered by this skill).
license: Complete terms in LICENSE
---

# Travel search

Reduck scripts that turn train search (Trainline) and short-stay search
(Airbnb) into callable building blocks. Each script below is a pointer — read
its contract (`read_script`) for the exact args and output. They run against
`handle:"reduck"`. The skill only *runs* these published scripts; it never
writes or publishes a script.

## Scripts

### Trains — `host:"thetrainline.com"`

- `@reduck/thetrainline.com/search_journeys` — `(from, to, date, includeStops?, max?)`
  → `{origin, destination, journeys}`. `from`/`to` are free text (city or
  station name, e.g. "Paris", "Lyon Part-Dieu", "London"); Trainline's own
  autocomplete resolves them. `date` is `YYYY-MM-DD` (defaults to 08:00) or
  `YYYY-MM-DDTHH:mm` — journeys departing after that time. Each journey has
  `departAt`, `arriveAt`, `duration` (ISO-8601, e.g. `PT2H4M`), `changes`, and
  one or more `legs` (one per train actually boarded). Pass `includeStops:true`
  to also get, per leg, **every calling point of that physical train** — not
  just the boarding/alighting stations — with scheduled + realtime arrival/
  departure and platform when available.

### Short stays — `host:"airbnb.com"`

- `@reduck/airbnb.com/search_listings` — `(location, checkin?, checkout?, adults?, children?, infants?, pets?, page?, amenities?, category_tag?, l2_property_type_id?, titleStartsWith?, query?)`
  → `{url, page, count, maxPage, listings}`. `location` is free text (e.g.
  "Paris" or "Lisbon, Portugal"). Up to 18 listings/page, capped around 15
  pages — paginate with `page` rather than expecting one call to return
  everything.
- `@reduck/airbnb.com/get_listing` — `(id, checkin?, checkout?, adults?, only_available?)`
  → full listing detail: title, property type, capacity, rating (+ per-category
  ratings), host, images, description, sleeping arrangement, house rules,
  lat/lng, and the month-by-month availability calendar. `id` is the numeric
  Airbnb room id — take it from a `search_listings` result, don't ask the user
  to supply one from memory.

## System prompt

1. **Train times / "quel train pour aller de X à Y"** → `search_journeys(from, to, date)`.
   Only pass `includeStops:true` when the user actually wants the intermediate
   stops (e.g. "où s'arrête ce train", "est-ce qu'il passe par Z", "horaires
   détaillés") — it costs one extra request per unique train and most
   "what time does the train leave" questions don't need it. When summarizing,
   report each leg's `train`/`trainNumber`/`carrier` and `changes` — a
   0-change result is a direct train, not a coincidence worth omitting.

2. **Reading `stops`** — the calling points are the train's own full route,
   which can start before and end after the segment the user asked about
   (e.g. a Marseille→Nice leg that's physically part of a train running
   Avignon→Ventimiglia). `type: "origin"/"destination"` refers to *that
   train's* route, not the passenger's boarding/alighting point — don't
   present the train's own origin as "where the user should get on."

3. **Airbnb search** → `search_listings(location, checkin, checkout, adults)`.
   Only page past page 1 if the user wants more than ~18 options or asks for
   "tous les logements" / an exhaustive sweep. Use `amenities`/`category_tag`
   to narrow instead of client-side filtering when the site exposes the
   filter — check the input schema's amenity id list.

4. **Airbnb listing deep-dive** → `get_listing(id, checkin, checkout)` once you
   have an `id` (from search, or from a URL/listing the user pasted — the id
   is the number in `airbnb.com/rooms/<id>`). Use `only_available:true` when
   the user only cares about which dates are bookable, not the full calendar.

## Constraints & gotchas

- **Never publish** a script to the org — this skill only `run_script`s the
  existing `@reduck` versions.
- **Trainline is DataDome-protected.** A burst of calls in a short window (from
  the same session/device) can trigger a slide/image CAPTCHA challenge that
  the script cannot and must not try to solve programmatically — space out
  calls, and if a run comes back with a captcha/verification page, tell the
  user this is a site-side rate limit, not a broken script. Retrying
  immediately in a loop makes it worse.
- **Trainline location resolution** is "first autocomplete match" — for an
  ambiguous free-text query (a city with several stations), the resolved
  `origin`/`destination` in the output tells you what was actually searched;
  surface it if it doesn't look right rather than assuming it matched intent.
- **Airbnb `search_listings`** amenity/property-type filters are the site's
  own filter-pill ids (sparse, non-sequential) — see the input schema's
  description for the common ones rather than guessing.
- Treat `null` fields (Airbnb host stats, Trainline `platform`, realtime
  status) as "not exposed for this listing/session," not as zero or an error.
