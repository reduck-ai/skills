---
name: amazon-research
description: |
    Product research, listing and review analysis, and category watch on Amazon US.
    Use to search Amazon or compare prices, pull a product's full listing and dig
    into its reviews (ratings breakdown, recurring complaints and praise), or scan
    a category for high-demand / poorly-rated openings. US-only.
    NOT for placing orders, seller-central actions, or non-US marketplaces.
---

# Requirements

- **Reduck MCP, with the browser extension installed.** If it isn't set up, follow the instructions at [start.reduck.ai](https://start.reduck.ai/).

- **`reduck/amazon.com/search-products`**
- **`reduck/amazon.com/get-product`**
- **`reduck/amazon.com/list-category`**
- **`reduck/amazon.com/get-product-reviews`**

Read their contracts live with `read_script` Reduck MCP.

`get-product-reviews` runs as the Amazon account signed into your paired browser;
the other three are public.

# The flow

Pick the workflow from the user's intent and stop at the first step that answers
it — don't enrich listings you won't use.

1. **Search and price** — `search-products`. Paginate only if the first page
   doesn't cover the ask. Return title, price, rating, review count.
2. **Listing and reviews** — `get-product` for the listing and its
   `rating_breakdown`, then `get-product-reviews` over pages 1..N for a real
   sample (20+ reviews = 2 pages or more). Concatenate, then summarize what
   actually recurs: complaints against praise, each with its star level and how
   often it comes up.
3. **Category watch** — `list-category` on a search-results URL, take the top
   organic ASINs, `get-product` each, and look for the gap: **strong demand**
   (high review count) with **weak satisfaction** (low rating, or a heavy 1–2★
   share of `rating_breakdown`). That gap is the opportunity.

# Rules

- **US-only.** Pass `zipCode` (default `10001`) so price and availability resolve
  to a US locale. Another ZIP only if the user asks.
- **Flag `sponsored` rows** so paid placement is never read as organic ranking.
- **Treat a null field as "not exposed", not as zero.** `list_price`, `seller`
  and `breadcrumb` are routinely null.
- **Prefer `sortBy: helpful` over `recent` when paginating reviews.** Under
  `recent` a given page shifts between calls as new reviews arrive, so page N
  isn't stable. Amazon hard-caps reviews at 10 pages of 10.
- `list-category` takes an Amazon `/s?` search-listing URL only. The real Best
  Sellers chart isn't reachable, so a category scan is an approximation — say so.
- Keep concurrency modest across ASINs and pages; Amazon rate-limits, and a cold
  listing page hits an anti-bot wall.
