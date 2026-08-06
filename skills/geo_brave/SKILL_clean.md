---
name: geo_brave
description: |
    Brave Search's optimization — the substrate behind Claude's web_search —
    and how to diagnose whether a domain is in it. Use for GEO/AEO work: "why don't we
    show up in Claude", "are we indexed", "optimize for AI search visibility",
    "get cited by LLMs". NOT for Google SEO (different index, different levers).
---

# Requirements

- **Reduck MCP, with the browser extension installed.** If it isn't set up, follow the instructions at [start.reduck.ai](https://start.reduck.ai/).

- **`reduck/search.brave.com/search`**
- **`reduck/search.brave.com/submit_url`**
- **`reduck/claude.ai/ask`**

Read their contracts live with `read_script` Reduck MCP.

# GEO on Brave

First principle: **an LLM can only cite what its search tool retrieves.** Retrieval
requires being in the index, with readable content.

Given a prompt p like "How to use Claude with LinkedIn", an AI Assistant can do web search queries q, which return results r = (url, description = summary(page)).
The goal of GEO is to focus on a few p, observe the q, then try to optimize the content of the pages to:
- Appear in the search results, primary goal
- Convince the LLM that to mention one's product once present among the search results, secondary goal

## The flow

One `ask` gives you the queries. Harvest them — never invent them. Everything after that runs
once per query.

**Once per surface** — a surface is a domain plus a way of rendering pages. Re-run when you add
a subdomain, add a new rendering path, or change infrastructure. Otherwise you are trusting a
stale pass.

| Probe | Tells you |
| --- | --- |
| `search(brand)` | whether your domain ranks for your own name — and what ranks instead of it |
| `search(site:me)` | whether anything of yours is indexed and read. **A floor, never a count** |
| fetch one URL per rendering path | whether a crawler can read you at all |

**Per query worth winning**

1. **Breadth** — `search(q)`, then fetch every result. Where am I, and how many of these pages
   mention my name?
2. **Where I stand** — `search(site:me q)`. Nothing means no ammunition. Something that never
   appeared in step 1 means you have it and it is losing.
3. **What winning looks like** — `search(site:winner q)`, then fetch. The winner is a page that
   **ranks high *and* was cited by the model**; one the model skipped is not a template.

The three steps end in a single comparison — length, structure, how often the query's main
phrase appears, freshness — theirs against yours. That comparison is the action.

# 1 - Assess from prompt to sources to answer

**Why.** "We weren't mentioned" has three different causes, and each needs a different fix.
Guessing wastes months. One run tells you which one you have.

Run `ask` on a prompt you want to win. Read three fields:

- **queries** — what the model actually searched. Rarely your words.
- **sources** — every page its tools read, not only the ones the answer cites.
- **answer** — what the user sees.

**One `ask` is a single draw, not a measurement.** The model may reformulate differently, or not
search at all, on the next run of the same prompt. Repeat a prompt before you conclude anything
from it, and treat "it named us once" as weaker evidence than "it named us three times out of
three".

| What you see | Cause | What to do |
| --- | --- | --- |
| no queries | the prompt never triggers a search | pick a different prompt — nothing else can work |
| searched, you are not in sources | not retrieved | go to §2 |
| in sources, not in the answer | read and passed over | rewrite the page |

**The pages returned need not be from your domain to be named.** The model reads the *text*
of what it retrieves, so a mention of you inside someone else's page counts just as much as a
page you own — a press article, a competitor's round-up, a marketplace listing. Check both.

**Running example — one vendor, used throughout this file.** They sell insurance-distribution
software.

- *"Which insurers let you get a quote inside ChatGPT?"* → the model searched
  `insurance quote inside ChatGPT partners` → 9 sources, **none of them theirs** → **the answer
  named them anyway**, because 2 of those 9 pages contained "powered by <vendor>'s AI
  distribution infrastructure", lifted verbatim from a partner's press release.
- *"How can an insurance company sell products inside ChatGPT and Claude?"* → the model
  searched `ChatGPT apps SDK sell products directly in chat` → 17 sources, zero mentions →
  **not named**.

Same company, same day. The wording of the prompt decided which part of the index the model
searched, and only one of them contained them.

# 2 - Analyse current ranking

**Why.** "Not retrieved" has two causes that look identical and need opposite work. Either the
crawler cannot read your page — and then no amount of writing helps — or it can, and you are
simply not scored high enough. Find out which before spending anything.

Four checks. The first two catch each other's mistakes, so never run one alone; the fourth is
only needed when you are about to act on a page looking absent.

1. **Fetch your own URL with a plain HTTP client.** *Can* a crawler read it? Two failure modes:
   a bot-protection challenge, or `200 OK` with an empty body because the page is drawn by
   JavaScript. Brave's crawler advertises no user agent of its own, so it can never be added to
   a verified-bot allowlist — to bot protection it looks exactly like the traffic being blocked.
2. **`search` with `site:yourdomain.com`.** *Has* Brave read it? For each result ask whether the
   description describes **that page**. A page-specific one means yes. The placeholder "We
   cannot provide a description for this page right now" means Brave holds the URL and nothing
   else. A generic site-wide line — or one belonging to a different page — means Brave indexed
   the shell, not the content.
3. **`search` with `site:yourdomain.com <query>`.** *What do I have that is relevant to this
   query?* Bare `site:` returns a small ranked sample, **not everything Brave holds** — read it
   as a floor and never as a count. On one site the bare form returned 2 URLs and the query form
   returned 12, a six-fold understatement that would have sent us fixing distribution when the
   real problem was ranking.
4. **To prove one page is missing, `search` a distinctive sentence from it in quotes.** Both
   `site:` forms are ranked samples, so neither can establish absence — a page missing from one
   query's sample turns up in another's. An exact phrase is the only probe that answers "is *this
   page* in the index". Nothing back means genuinely unindexed. Use this before any `submit_url`.

Judge **per URL**, not per domain. One site is routinely in three of these rows at once.

| fetch | `site:` and `site: <query>` | meaning | fix |
| --- | --- | --- | --- |
| readable | page-specific description | outranked, not invisible | content |
| readable | absent from both forms **and** from an exact-phrase search | crawler can read it, Brave never came | `submit_url` |
| blocked | placeholder, generic, or nothing | crawler cannot read it | infrastructure — nothing else counts |
| blocked | page-specific description | **your fetch is wrong, not the site** | re-test from another network |

Both bottom rows are real. One site refused our client with `403` while ranking at #12 with a
fresh, page-specific description — the block was aimed at our IP, not at crawlers. Another
served an empty JavaScript shell on every route, and Brave had indexed its terms page under the
*homepage's* title and description. Never diagnose on the fetch alone, and never take a
description at face value without checking it belongs to the page.

`operatorsApplied: false` means Brave found too few documents matching your operator, dropped
it, and answered a relaxed query instead. Read it two ways at once. Discard the **results** —
they are soft relevance over the whole web, not filtered by your `site:`. But the **flag itself
is signal**: the domain really is thin on this topic. Separate "thin here" from "nothing at all"
against bare `site:` — one site came back `false` with a single URL indexed, another `true` with
twelve. The flag is vacuously `true` for a query carrying no operators, so only read it when you
passed one.

**Outranked** → compare your page against the ones that rank for the words the model actually
searched (§1 gave you those words). The difference is usually how often the query's main phrase
appears: on one query the pages at rank 1 and rank 4 used it 32 and 23 times, the unranked
challenger 4 times.

**Example — same vendor.** Three of their surfaces, three different verdicts:

- **Homepage.** Fetch readable; `site:` returns a page-specific description. Indexed and read,
  simply outranked. Fix: content.
- **A post that should have ranked, missing from both `site:` forms.** Suspicion only — both are
  samples. An exact sentence from it, searched in quotes, is what decides. Returns nothing →
  `submit_url`. Returns the page → it was indexed all along and you have a ranking problem.
  Never submit a page that is a JavaScript shell: you only re-index the boilerplate.
- **`app.<vendor>.ai/terms`.** Fetch returns `200` with an empty body; `site:` shows it under the
  *homepage's* title and description. A JavaScript shell, indexed as boilerplate. Fix:
  server-render it.

Bare `site:` returned only 2 URLs for this domain, which looked fatal. `site: <query>` returned
12, ten of them blog posts with page-specific descriptions. Trusting the bare form would have
sent them submitting 36 URLs that were already in the index.

# 3 - Choose the lever

**Why.** §1 and §2 tell you what is broken. They do not tell you what is worth fixing. The
cheapest lever is usually not on your website at all, and you cannot see it without looking at
what the ranking pages actually say.

Fetch the pages that rank for the query and count how often your name appears in them.

- **If it appears in none of them, no model can name you.** It only knows what it read. This is
  the one hard rule, and it holds regardless of how good your own pages are.
- **The dose is tiny.** One mention, in one retrieved page, was enough to get named.

So there are two independent paths, and only the first needs your website to work:

1. **Rank your own page.** §2 tells you whether that is even possible yet.
2. **Be named inside pages that already rank.** This is the cheaper path and the one people leave
   as an aspiration, so here is the actual work:
   - **Fix the sentence partners use.** Whatever clause appears in their press releases is what
     the model reproduces, so make it self-describing — the product category, not just the name —
     and put it in the co-marketing agreement as a required line.
   - **Get into the round-ups that already rank.** Step 1 of the flow told you which pages those
     are. Most take submissions or updates; ask.
   - **Write the round-up yourself.** In several categories every ranking page is a vendor's own
     "N best tools" post. If that is the format winning your query, it is available to you too.
   - **Brief the trade press in your vertical.** Mentions cluster by vocabulary: coverage in your
     niche's outlets is what puts you in the corpus the model pulls for niche-worded prompts.

**Example — same vendor, two queries.** Count their name across the pages that rank for each:

- The generic query (`ChatGPT apps SDK sell products directly in chat`) — **0 mentions across
  the 20 ranking pages.** Never named, on any prompt that reformulated this way.
- The insurance-worded query (`insurance ChatGPT app distribution`) — **5 of the 19 ranking
  pages** carried "powered by *<vendor>*'s AI distribution infrastructure". The model named
  them, reproducing that phrase almost word for word.

Not one of their own pages was retrieved in either case.

Which means the boilerplate in someone else's announcement is how the model describes you.
Write that sentence deliberately.



# Re usable code snippets