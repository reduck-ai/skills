---
name: geo_brave
description: |
    Brave Search's optimization — the substrate behind Claude's web_search —
    and how to diagnose whether a domain is in it. Use for GEO/AEO work: "why don't we
    show up in Claude", "are we indexed", "optimize for AI search visibility",
    "get cited by LLMs". NOT for Google SEO (different index, different levers).
---

# GEO on Brave

First principle: **an LLM can only cite what its search tool retrieves.** Retrieval
requires being in the index, with readable content.

Given a prompt p like "How to use Claude with LinkedIn", an AI Assistant can do web search queries q, which return results r = (url, description = summary(page)).
The goal of GEO is to focus on a few p, observe the q, then try to optimize the content of the pages to:
- Appear in the search results, primary goal
- Convince the LLM that to mention one's product once present among the search results, secondary goal

## What is established

- **Brave's index is independent** — not Bing, not Google.
  Proof: [search.brave.com/help](https://search.brave.com/help) — "built on its own
  independent search index. It doesn't rely on Big Tech companies like Bing".
- **Scale and refresh: ~40B pages, >100M pages added or refreshed per day.**
  Proof: [brave.com/blog/search-api-growth](https://brave.com/blog/search-api-growth/)
  (Feb 2026). Older figure on [brave.com/search/api](https://brave.com/search/api/):
  "over 30 billion pages… over 100 million page updates every day".
  Arithmetic: 100M/40B = **0.25% of the index per day**, a ~400-day average round trip.
  So refresh is sharply prioritized — the long tail is effectively never re-fetched, and
  a manual submit is the only lever a site owner has over its own page.
- **The crawler has no distinguishing user agent, deliberately.**
  Proof: [Brave Search Crawler](https://search.brave.com/help/brave-search-crawler) —
  "does not advertise a differentiated user agent because we must avoid discrimination
  from websites that allow only Google to crawl them".
  Consequence: it is invisible in your logs, and **it can never appear on any
  verified-bot allowlist** (Cloudflare, Vercel, Akamai). To a bot-protection product it
  looks exactly like the traffic being challenged. This is the single most important
  fact in this file.
- **`robots.txt` does not control indexing; `noindex` does, and only after a re-fetch.**
  Proof: same page — "robots.txt is not used to prevent a page from being indexed…
  Brave needs to re-fetch it in order to apply the changes".
- **Discovery is crawler + Web Discovery Project (WDP)**, an opt-in, off-by-default
  telemetry stream from Brave browser users.
  Proof: same page, and [WDP help](https://support.brave.app/hc/en-us/articles/4409406835469-What-is-the-Web-Discovery-Project).

## Ranking: what Brave actually discloses

Brave has never published a ranking-signal document. Two sources, descending in value:

- **The closest thing to a signal list is the WDP help page**, stating what Brave needs
  in order to rank relevantly: keyword match (exact words, parts, synonyms); how recent
  searches are; **how often a result is clicked for a keyword**; keyword popularity;
  **what pages are popular or novel**; which sites only allow Googlebot.
  Proof: [WDP help page](https://support.brave.app/hc/en-us/articles/4409406835469-What-is-the-Web-Discovery-Project).
  Read the omission as data: **backlinks, domain authority, and link-graph signals are
  named nowhere** — not there, not in Brave's own paper, not in the API docs.
- **Retrieval architecture, from Brave's own paper:** a **recall phase** matching the
  query against billions of pages with "simple features", cutting to a candidate set
  "typically in the order of few thousands"; then **precision phases** with "increasingly
  sophisticated and costly models"; final ranking over a very small set.
  Proof: [goggles.pdf](https://brave.com/static-assets/files/goggles.pdf) §4.
  Consequence: **the recall phase is keyword matching over indexed text.** A page with no
  indexed body text cannot enter the candidate set at any price.




## Requirements

- **Reduck MCP, with the browser extension installed.** If it isn't set up, follow the
  instructions at [start.reduck.ai](https://start.reduck.ai/).

## Scripts

Three Reduck scripts cover the loop: one reads the index, one writes to it, one reads the
outcome that actually matters.

- **`reduck/search.brave.com/search`** — read the index (`site:` queries, `offset` paging).
- **`reduck/search.brave.com/submit_url`** — request a re-fetch of one URL.
- **`reduck/claude.ai/ask`** — ask Claude one question, read what its tools surfaced.

`ask` is what makes any of this measurable. Alongside the answer it returns
`webSearchQueries` — the queries Claude actually issued — and `sources`: **the candidate
pool its `web_search`/`web_fetch` surfaced, not only what the answer cites** (each entry
tagged with which tool found it). That exposes the layer between prompt and answer that is
otherwise invisible, and it is what turns "we weren't mentioned" into a located fault.
`sources` is empty when no tool ran.

Read their contracts live with `read_script` rather than trusting a copy: they carry the
args, return shapes and caveats.

The two Brave scripts need no login. `ask` requires a signed-in claude.ai session — there
is no anonymous chat; chain `reduck/claude.ai/login` if the session has lapsed. One
IP-keyed rate limiter guards both Brave scripts, so a captcha means back off 30-60s rather
than retrying. Each `ask` also creates a real conversation, so a wide sweep leaves clutter
— `reduck/claude.ai/delete_chat` takes the `conversationId` values back out.

## Reading a failure

Run `ask` on a prompt you want to win, then attribute the miss to one stage:

| Observation | Stage that failed | Read it as |
|---|---|---|
| `webSearchQueries: []` | Nothing was retrieved | Wrong prompt to target — answered from memory, no GEO lever applies |
| Searched, you are absent from `sources` | Retrieval | Drop to the `site:` probe to split index vs rank |
| Present in `sources`, absent from the answer | Selection | The only genuine content problem — you were read and passed over |

**Judge yourself on `sources`, never on the prose.** A model naming your product because it
is a connected tool in the session says nothing about discoverability.

## Diagnosing a domain

Run `site:example.com` on search.brave.com and read **two** signals:

1. **URL present** → Brave knows the page exists.
2. **Description present** → Brave actually fetched and read it.

A result reading **"We cannot provide a description for this page right now"** means
**URL-known, content-unread**. That page has no body text in the index, so it cannot
survive the recall phase. This is the diagnostic that matters, and it is invisible if you
only count results.

Through the `search` script that state is a field, not a judgement call: the result comes
back with **`snippet: null`**. Also check **`operatorsApplied`** — when it is `false` Brave
dropped your `site:` and relaxed the query, so the results are soft-relevance and a real
"not indexed" is indistinguishable from a filtered one. Treat that run as no data and
retry, never as a negative.

Then contrast against `site:example.com` on Google. Google indexed but Brave blank
isolates the cause to crawler access, not content.

Operator caveat, proven: `site:X OR site:Y` returned **"search operators were not
applied"** on 2026-08-05. Brave's own page calls operators "experimental and in the early
stage of development" ([operators](https://search.brave.com/help/operators)).
**Run one `site:` per query.**

## Worked case: a site behind a bot challenge

A real diagnosis, run 2026-08-05, generalised. The domain was a SaaS marketing site on
Vercel with bot protection enabled. Symptoms, in the order the probes surface them:

- **Brave `site:example.com` → exactly one result**: the homepage, title only,
  "We cannot provide a description for this page right now", pager greyed out. Deeper
  paths and subdomains → nothing.
- **Google `site:example.com`** → homepage with a full snippet, plus `/pricing`, several
  subdomains, and more. **This contrast is the whole diagnosis**: content that Google
  reads and Brave cannot is an access problem, not a content problem.
- **Brave indexed the product, just not the owned domain.** A plain brand-name query
  surfaced the Chrome Web Store listing and the npm package with proper descriptions.
  Third-party surfaces out-described the owned domain, because they sit on crawlable hosts.
- **Cause — the bot challenge.** Real Chrome hitting `/robots.txt` first got
  **"Vercel Security Checkpoint — We're verifying your browser"**, revealing the file only
  after the JS challenge resolved. Every non-browser client got `HTTP 429` plus the
  checkpoint page, on `/`, `/robots.txt` **and** `/sitemap.xml`:

  ```
  Googlebot UA   /  /robots.txt  /sitemap.xml   HTTP 429  << CHECKPOINT
  curl/8.0       /  /robots.txt  /sitemap.xml   HTTP 429  << CHECKPOINT
  Chrome UA      /  /robots.txt  /sitemap.xml   HTTP 429  << CHECKPOINT
  ```

- The `robots.txt` itself was correct — only authenticated app routes disallowed, sitemap
  declared. **The file was fine; it was unreachable.** A crawler that cannot read
  `robots.txt` or `sitemap.xml` has no route in at all.
- **Honest limits of that experiment:** the Googlebot-UA row came from a residential IP,
  which real reverse-DNS verification rejects — it does *not* show real Googlebot being
  blocked, and Google's index proved it wasn't. The `429` may partly reflect the test's own
  request volume. Neither weakens the conclusion: the Brave index state was observed
  before any of the curl traffic, and an unidentifiable crawler cannot be allowlisted.

## The rule this yields

> Bot protection on a public marketing or docs surface is a GEO kill switch.
> Googlebot survives it via verified-bot allowlisting. Brave, having no user agent to
> allowlist, cannot. Result: URL indexed, content blank, permanently unretrievable.

**So the first GEO action on any domain is never content — it is confirming a crawler can
read the page.** Check `site:` for descriptions, and check what a plain HTTP client gets.
Content and phrasing work is wasted spend until that passes.

## Is Claude's web_search Brave-backed? Experiment, 2026-08-06

Method: ask a question via `reduck/claude.ai/ask`, read the `webSearchQueries` and
`sources` it returns (the candidate pool, not just cited sources), then replay each query
verbatim on Brave and — as a control — on Google.

**Result: 32 of 32 of Claude's sources appeared in Brave's first page. Zero misses.**

| Claude's query | sources | in Brave | in Google |
|---|---|---|---|
| `Claude LinkedIn Sales Navigator integration MCP connector` | 8 | 8/8 (top 20) | 6/8 (top ~28) |
| `best MCP servers browser automation 2026` | 8 | 8/8 (top 8) | 5/8 (top 9) |
| `chrome-devtools-mcp vs playwright mcp browser automation comparison` | 7 | 7/7 (top 12) | not run |
| `AI agent automatically download invoices from vendor portals` | 9 | 9/9 (top 13) | not run |

Strongest single datapoint: for `best MCP servers browser automation 2026`, Claude's 8
sources were **exactly Brave's top 8 as a set** — same eight URLs, reordered. Google's top
9 for that query included `daily.dev`, `skillsllm` and `medium.com`, none of which Claude
saw, and a *different* unbrowse.ai URL than the one Claude read.

**Status: strong behavioral evidence, not documentary proof.** No Anthropic or Brave
statement names the other; Brave's [blog](https://brave.com/blog/search-api-growth/) claims
its API supplies "most of the top-10 LLMs" but names no customer.
[trust.anthropic.com/subprocessors](https://trust.anthropic.com/subprocessors) is
JS-rendered and was not read. What lifts this above coincidence is the asymmetry against
the Google control plus the exact set match — and that Brave was queried from a different
IP and session than Anthropic's, which should have added noise and did not.

### Observed behaviour of the layer on top of Brave

- Takes a **contiguous slice of Brave's head**, roughly top 8–13. Never anything deep.
  A page at Brave position ~12+ was never in the pool.
- **Reorders** — Claude's source order never matched Brave's rank order.
- **Filters inconsistently.** On the LinkedIn query it dropped every directory and GitHub
  result and kept prose articles. On the devtools query it took only one of two
  `stevekinney.com` and one of two `vibebrowser.app` pages. But on the invoice query it
  took **both** `glideapps.com` URLs — so per-domain dedup is not a fixed rule.

### Consequences for GEO

- **Claude searches its own reformulation, not the user's words.** "How to use Claude with
  LinkedIn Sales Navigator?" became `Claude LinkedIn Sales Navigator integration MCP
  connector`. Reformulations were keyword-dense, tool-named, often year-stamped (`2026`).
  Those are the keywords that matter, and `ask` surfaces them directly via
  `webSearchQueries` — a free keyword-research instrument aimed at Brave.
- **Fan-out is wide but shallow**: one question produced up to 5 queries and 43 sources,
  yet each query only reached ~10 URLs deep.
- **Not every question searches.** "How can an AI agent automate filling out forms on
  legacy web portals?" returned `webSearchQueries: []` — answered from parametric
  knowledge. Generic how-to questions may never trigger retrieval; specific, current,
  comparative or vendor-named ones did.
- **Being a connected tool in the session is not visibility.** A model naming your product
  because it is loaded as a tool tells you nothing about discoverability. Only its presence
  in `sources` does. Judge yourself on the candidate pool, never on the prose.

The crawler-access finding above is independent of this and holds for **every** engine
whose crawler cannot be allowlisted.
