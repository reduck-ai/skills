---
name: linkedin-leads
description: |
  Prospect and qualify B2B leads from LinkedIn activity. Use when the user wants
  to find who is posting or engaging on a topic, build a lead list from a post's
  reactors, or qualify the resulting profiles/companies. Discovers recent posts,
  pulls each post's content and reactors, then enriches the promising ones into a
  shortlist. NOT for writes (messaging, connection requests) or Sales Navigator.
license: Complete terms in LICENSE
---

# LinkedIn leads

Reduck scripts that turn LinkedIn flows into callable building blocks. Each script
below is a pointer — read its contract (`read_script`) for the exact args and
output. They are `loggedIn`, so they need a LinkedIn session exposed via
`reduck local --cookies` (see the `reduck` skill for the bridge lifecycle and how
to run a script).

## Scripts

- `@reduck/google.com/search_site` — `(query, limit)` → search-result URLs. Used to run `site:linkedin.com/posts <topic>` against Google (not LinkedIn search): a real recency filter and no LinkedIn rate cap. Yields the post URLs that seed everything else.
- `@reduck/linkedin.com/get_post` — `(postUrl)` → the post's content and author. The "what was said / by whom" for a discovered URL.
- `@reduck/linkedin.com/get_post_reactors` — `(postUrl, limit)` → the people who reacted (name + member-id profile link). The engaged audience; the raw lead pool before qualification.
- `@reduck/linkedin.com/get_profile` — `(profileUrl | member-id link)` → the canonical profile. Resolves a reactor's member-id link to the real profile and is the input the other profile scripts need — always the first enrichment call.
- `@reduck/linkedin.com/get_profile_experience` — `(profileUrl)` → roles / tenure. Confirms the person is who the post suggested (title, seniority, current company).
- `@reduck/linkedin.com/get_company_info` — `(companyUrl | name)` → firmographics (size, industry). Sizes the account behind a qualified person.

## System prompt

Orchestrate the scripts in four stages; stop at the first stage that answers the
user's question — don't enrich what you won't use.

1. **Discover** — `search_site` over `site:linkedin.com/posts` plus the topic,
   newest first, scoped to the time window the user asked for. Yields post URLs.
   (Google, not LinkedIn search: a real recency filter and no LinkedIn rate cap.)
2. **Engage** — per post, `get_post` for the content/author and `get_post_reactors`
   for the engaged audience. A post too fresh to have reactions yields nothing here
   — that's expected, not a failure.
3. **Qualify** — score the reactors as leads (the `icp` skill, if installed, is the
   rubric; otherwise apply the user's stated criteria). Keep only the shortlist
   worth a human's attention; a viral post's reactions are mostly noise.
4. **Enrich** — shortlist only: `get_profile` first (it resolves a reactor's
   member-id link to the canonical profile and is the input the other profile
   scripts need), then `get_profile_experience` to confirm the person, and
   `get_company_info` to size the account. Stop as soon as the verdict is decided.

Deliver per lead: the verdict and the one signal that earned it. Run the per-post
and per-lead steps concurrently, but keep concurrency modest — a wide browser
fan-out is its own failure mode.
