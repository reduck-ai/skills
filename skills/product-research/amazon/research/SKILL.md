---
name: amazon-research
description: |
  Product research, listing/review analysis, and category watch on Amazon US.
  Use when the user wants to search Amazon for a product or compare prices, pull
  a product's full listing and dig into its reviews (ratings breakdown, recurring
  complaints/praise), or scan a category to spot high-demand / poorly-rated
  opportunities. Drives four published @reduck/amazon.com scripts as building
  blocks. US-only (default ZIP 10001). NOT for: placing orders, seller-central /
  account actions, or non-US marketplaces.
license: Complete terms in LICENSE
---

# Amazon research

Reduck scripts that turn Amazon US flows into callable building blocks. Each
script below is a pointer — read its contract (`read_script`) for the exact args
and output. They run against `handle:"reduck"`, `host:"amazon.com"`. The skill
only *runs* these published scripts; it never writes or publishes a script.

Amazon is **US-only** here: pass `zipCode` (default `10001`) so price and
availability match a US locale. `get-product-reviews` is `loggedIn:true` — it
needs an Amazon session exposed via `reduck local --cookies` (see the `reduck`
skill for the bridge lifecycle and how to run a script). The other three are
public, no login.

## Scripts

- `@reduck/amazon.com/search-products` — `(query, page?, zipCode?)` → listings `{asin, title, price, list_price, rating, review_count, image_url, sponsored}`. ~16-22 organic results/page, cap ~20 pages. No seller rating or bulk tiers (not on the search page). The entry point for "find / price a product".
- `@reduck/amazon.com/get-product` — `(asin, zipCode?)` → full listing: `price, list_price, rating, review_count, rating_breakdown` (% per star), `seller, availability, feature_bullets, variant_asins`, etc. `list_price` / `seller` / `breadcrumb` are sometimes null — treat null as "not exposed", not zero.
- `@reduck/amazon.com/get-product-reviews` — `(asin, page?, sortBy?(recent|helpful), filterByStar?, reviewerType?, mediaType?, filterByKeyword?, zipCode?)` → `product{…, starBreakdown}` + `reviews[]`. **`loggedIn:true`** (bridge `--cookies`). 10 reviews/page, cap 10 pages. For N pages, call page 1..N and concatenate.
- `@reduck/amazon.com/list-category` — `(url, zipCode?)` where `url` MUST match `^https://www.amazon.com/s?…` → `{heading, products:[{asin, position, sponsored}]}`. Card-level only (no price/rating) → chain into `get-product`. Does NOT accept `/gp/bestsellers` — so "best-sellers" is approximated by a search-results URL, not the real Best Sellers chart.

## System prompt

Pick the workflow from the user's intent; stop at the first step that answers the
question — don't enrich listings you won't use. Always pass `zipCode` (default
`10001`).

1. **Search / price** — *"cherche X sur amazon", "prix de X", "compare les X"* →
   `search-products(query)`. Paginate (`page`) only if the first page doesn't
   cover the ask. Return title / price / rating / review_count, and flag
   `sponsored` rows so they aren't read as organic ranking.

2. **Listing + reviews deep-dive** — *"détaille l'ASIN Y", "les avis de Y", "c'est
   bien noté ?"* → `get-product(asin)` for the listing and `rating_breakdown`,
   then `get-product-reviews(asin)` looping pages 1..N for a real sample (≥20
   reviews = 2+ pages; use `sortBy:recent` for current sentiment, `filterByStar`
   to zoom on 1-2★). Concatenate pages, then summarize: recurring complaints vs
   recurring praise, with the star level and how often each theme recurs. Needs
   the `--cookies` bridge; if reviews fail, it's almost always the login session.

3. **Category watch / opportunities** — *"best-sellers en [catégorie]",
   "opportunités sur [niche]"* → `list-category(url)` with a search-results URL
   (`https://www.amazon.com/s?k=<category>`; the real Best Sellers chart is not
   accessible, so this is an approximation — say so). Take the top organic ASINs
   (ignore `sponsored`), `get-product` each, then flag the gap: **strong demand**
   (high `review_count`) combined with **weak satisfaction** (low `rating` /
   high share of 1-2★ in `rating_breakdown`). Those are the opportunity signals.

Run per-ASIN and per-page steps concurrently but keep concurrency modest — a wide
browser fan-out is its own failure mode, and Amazon rate-limits.

## Constraints

- **US-only**, default `zipCode: 10001`. Different ZIP only if the user asks.
- `get-product-reviews` requires the **`reduck local --cookies`** bridge (it's
  `loggedIn:true`). The other three are public.
- **Never publish** a script to the org — this skill only `run_script`s the
  existing `@reduck/amazon.com` versions.
- Flag `sponsored` results so paid placement isn't mistaken for organic ranking;
  treat null fields as "not exposed", not zero.
