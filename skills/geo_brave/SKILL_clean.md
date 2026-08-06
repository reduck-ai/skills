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

## Scripts

- **`reduck/search.brave.com/search`** — read the index
- **`reduck/search.brave.com/submit_url`** — ask Brave to re-fetch one URL
- **`reduck/claude.ai/ask`** — ask Claude and see what its tools read

Read their contracts live with `read_script` Reduck MCP.

# GEO on Brave

First principle: **an LLM can only cite what its search tool retrieves.** Retrieval
requires being in the index, with readable content.

Given a prompt p like "How to use Claude with LinkedIn", an AI Assistant can do web search queries q, which return results r = (url, description = summary(page)).
The goal of GEO is to focus on a few p, observe the q, then try to optimize the content of the pages to:
- Appear in the search results, primary goal
- Convince the LLM that to mention one's product once present among the search results, secondary goal

# 1 - Assess from prompt to sources to answer

**Why.** "We weren't mentioned" has three different causes, and each needs a different fix.
Guessing wastes months. One run tells you which one you have.

Run `ask` on a prompt you want to win. Read three fields:

- **queries** — what the model actually searched. Rarely your words.
- **sources** — every page its tools read, not only the ones the answer cites.
- **answer** — what the user sees.

| What you see | Cause | What to do |
| --- | --- | --- |
| no queries | the prompt never triggers a search | pick a different prompt — nothing else can work |
| searched, you are not in sources | not retrieved | go to §2 |
| in sources, not in the answer | read and passed over | rewrite the page |

**The pages returned need not be from your domain to be named.** The model reads the *text*
of what it retrieves, so a mention of you inside someone else's page counts just as much as a
page you own — a press article, a competitor's round-up, a marketplace listing. Check both.

**Example.** A vendor selling insurance-distribution software, no page of theirs indexed:

- *"Which insurers let you get a quote inside ChatGPT?"* → the model searched
  `insurance quote inside ChatGPT partners` → 9 sources, **none theirs** → **the answer named
  them**, because 2 of those 9 pages contained "powered by <vendor>'s AI distribution
  infrastructure", lifted verbatim from a partner's press release.
- *"How can an insurance company sell products inside ChatGPT and Claude?"* → the model
  searched `ChatGPT apps SDK sell products directly in chat` → 17 sources, zero mentions →
  **not named**.

Same company, same day. The wording of the prompt decided which part of the index the model
searched, and only one of them contained them.

# 2 - Analyse current ranking

**Why.** "Not retrieved" has two causes that look identical and need opposite work. Either the
crawler cannot read your page — and then no amount of writing helps — or it can, and you are
simply beaten. Find out which before spending anything.

Two checks. Each catches the other's mistake, so run both.

1. **Fetch your own URL with a plain HTTP client.** *Can* a crawler read it? Two failure modes:
   a bot-protection challenge, or `200 OK` with an empty body because the page is drawn by
   JavaScript. Brave's crawler advertises no user agent of its own, so it can never be added to
   a verified-bot allowlist — to bot protection it looks exactly like the traffic being blocked.
2. **`search` with `site:yourdomain.com`.** *Has* Brave read it? For each result ask whether the
   description describes **that page**. A page-specific one means yes. The placeholder "We
   cannot provide a description for this page right now" means Brave holds the URL and nothing
   else. A generic site-wide line — or one belonging to a different page — means Brave indexed
   the shell, not the content. No result means the URL is not in the index at all.

Judge **per URL**, not per domain. One site is routinely in three of these rows at once.

| fetch | `site:` | meaning | fix |
| --- | --- | --- | --- |
| readable | page-specific description | outranked, not invisible | content |
| readable | missing | crawler can read it, Brave never came | `submit_url` |
| blocked | placeholder, generic, or nothing | crawler cannot read it | infrastructure — nothing else counts |
| blocked | page-specific description | **your fetch is wrong, not the site** | re-test from another network |

Both bottom rows are real. One site refused our client with `403` while ranking at #12 with a
fresh, page-specific description — the block was aimed at our IP, not at crawlers. Another
served an empty JavaScript shell on every route, and Brave had indexed its terms page under the
*homepage's* title and description. Never diagnose on the fetch alone, and never take a
description at face value without checking it belongs to the page.

If `operatorsApplied` comes back `false`, Brave dropped your `site:` filter and answered a
looser question. That is no data, not a zero — never read it as "not indexed".

**Outranked** → compare your page against the ones that rank for the words the model actually
searched (§1 gave you those words). The difference is usually how often the query's main phrase
appears: on one query the pages at rank 1 and rank 4 used it 32 and 23 times, the unranked
challenger 4 times.

**Example.** Two vendors, same day.

- One: `site:` returns a single URL with the "cannot provide a description" placeholder. A plain
  fetch of the homepage returns `429` and a browser-verification page. Their content is good and
  completely invisible. Only the infrastructure fix matters.
- The other: `site:` returns 2 URLs with real descriptions — but their 36 blog posts, readable
  and on exactly the right topics, are not among them. Indexed, just not deeply. `submit_url`
  is the fix.

# 3 - Choose the lever

**Why.** §1 and §2 tell you what is broken. They do not tell you what is worth fixing. The
cheapest lever is usually not on your website at all, and you cannot see it without looking at
what the ranking pages actually say.

Fetch the pages that rank for the query and count how often your name appears in them.

- **If it appears in none of them, no model can name you.** It only knows what it read. This is
  the one hard rule, and it holds regardless of how good your own pages are.
- **The dose is tiny.** One mention, in one retrieved page, was enough to get named.

So there are two independent paths, and only the first needs your website to work:

1. Rank your own page.
2. Be named inside pages that already rank.

**Example.** Two vendors, same method.

- One had **0 mentions across the 19 ranking pages** and was never named in any prompt we tried,
  despite a good product and a real site.
- The other had **no page of theirs in the index at all**, yet the model named them twice —
  because 1 to 2 of the 9 pages it read said "powered by *<vendor>*'s AI distribution
  infrastructure", a line lifted from a partner's press release. The model reproduced that
  phrase almost word for word.

Which means the boilerplate in someone else's announcement is how the model describes you.
Write that sentence deliberately.



# Re usable code snippets