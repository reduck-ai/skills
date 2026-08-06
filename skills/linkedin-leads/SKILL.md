---
name: linkedin-leads
description: |
    Prospect, qualify, and act on leads from LinkedIn. Use to find who posts or
    engages on a topic, build a lead list from a post's reactors or commenters,
    qualify the profiles and companies behind them, find who could introduce you,
    read the inbox, and — on a human-approved shortlist — reach out: connect,
    message, react, comment, repost. Optional Sales Navigator path on a paid seat.
    NOT for acting on a raw, unreviewed pool.
---

# Requirements

- **Reduck MCP, with the browser extension installed.** If it isn't set up, follow the instructions at [start.reduck.ai](https://start.reduck.ai/).

**Discover**

- **`reduck/google.com/search_site`**
- **`reduck/linkedin.com/search_posts`**
- **`reduck/linkedin.com/search_people`**
- **`reduck/linkedin.com/search_companies`**
- **`reduck/linkedin.com/suggest_locations`**

**Engage**

- **`reduck/linkedin.com/get_post`**
- **`reduck/linkedin.com/get_post_reactors`**
- **`reduck/linkedin.com/get_post_comments`**

**Enrich**

- **`reduck/linkedin.com/get_profile`**
- **`reduck/linkedin.com/get_profile_experience`**
- **`reduck/linkedin.com/get_profile_education`**
- **`reduck/linkedin.com/get_profile_posts`**
- **`reduck/linkedin.com/get_profile_comments`**
- **`reduck/linkedin.com/get_company_info`**
- **`reduck/linkedin.com/get_company_jobs`**
- **`reduck/linkedin.com/get_company_posts`**

**Inbox and own analytics**

- **`reduck/linkedin.com/list_inbox`**
- **`reduck/linkedin.com/get_thread`**
- **`reduck/linkedin.com/get_received_invitations`**
- **`reduck/linkedin.com/get_dashboard`**
- **`reduck/linkedin.com/get_post_analytics`**
- **`reduck/linkedin.com/get_profile_viewers`**

**Hiring signal**

- **`reduck/linkedin.com/search_jobs`**
- **`reduck/linkedin.com/get_job`**

**Sales Navigator** — paid seat only

- **`reduck/linkedin.com/sales_navigator_search_people`**
- **`reduck/linkedin.com/sales_navigator_search_accounts`**
- **`reduck/linkedin.com/sales_navigator_get_lead`**
- **`reduck/linkedin.com/sales_navigator_get_account`**
- **`reduck/linkedin.com/sales_navigator_list_lead_lists`**
- **`reduck/linkedin.com/sales_navigator_get_lead_list`**
- **`reduck/linkedin.com/sales_navigator_get_inbox`**
- **`reduck/linkedin.com/sales_navigator_get_thread`**
- **`reduck/linkedin.com/sales_navigator_save_lead_to_list`** — WRITE
- **`reduck/linkedin.com/sales_navigator_send_message`** — WRITE

**Act** — WRITE

- **`reduck/linkedin.com/connect`**
- **`reduck/linkedin.com/connect_with_note`**
- **`reduck/linkedin.com/send_message`**
- **`reduck/linkedin.com/react_post`**
- **`reduck/linkedin.com/unreact_post`**
- **`reduck/linkedin.com/comment_post`**
- **`reduck/linkedin.com/reply_post_comment`**
- **`reduck/linkedin.com/repost`**
- **`reduck/linkedin.com/follow`**
- **`reduck/linkedin.com/unfollow`**
- **`reduck/linkedin.com/withdraw`**
- **`reduck/linkedin.com/accept_invitation`**
- **`reduck/linkedin.com/ignore_invitation`**

Read their contracts live with `read_script` Reduck MCP.

Everything but `search_site` runs as the LinkedIn account signed into your paired
browser.

# The flow

Stop at the first stage that answers the question — don't enrich or act on what
you won't use.

1. **Discover** — pick the seed by what the user has:
   - *Default, no seat* — post-driven: `search_site` over `site:linkedin.com/posts`
     plus the topic (Google gives a real recency filter and no LinkedIn rate cap),
     or `search_posts` for LinkedIn's own ranking. Either yields post URLs.
   - *Criteria targeting, no seat* — `search_people` for profiles,
     `search_companies` for accounts. Skip Engage.
   - *Sales Navigator seat* — `sales_navigator_search_people` or `_accounts`.
     Never assume a seat; take this path only if the user says they have one.
   - *Hiring intent* — `search_jobs` then `get_job`, or `get_company_jobs` for one
     known account, then pivot to its people.
2. **Engage** (post-driven only) — per post, `get_post` for the content and author,
   then `get_post_reactors` (broad) and `get_post_comments` (higher intent — they
   wrote something). A post too fresh to have engagement yields nothing; that's
   expected, not a failure.
3. **Qualify** — score against the user's criteria and keep a shortlist. A viral
   post's reactions are mostly noise.
4. **Enrich** — shortlist only. `get_profile` first: it resolves a reactor's
   member-id link to the canonical profile and yields the `memberUrn` the rest
   joins on. Then experience and education to confirm the person, posts and
   comments for the personalization hook, `get_company_info` to size the account.
5. **Act** (optional, WRITE) — only on a human-approved shortlist, never the raw
   pool. Outreach: `connect` or `connect_with_note`, then `send_message` once
   connected. Feed warm-up: `react_post`, `comment_post`, `reply_post_comment`,
   `repost`. Inbound: `get_received_invitations` then `accept_invitation` or
   `ignore_invitation`. Cleanup: `withdraw`, `unfollow`.

Deliver per lead: the verdict and the one signal that earned it.

# Rules

- **Warm paths beat cold ones.** `search_people` takes `connectionOf`: pass a
  target's `memberUrn` and you get back the connections you share with them —
  your possible introducers — with no profile visit and no other filter. Check
  for a warm path before drafting a cold approach.
- **Never guess a `/company/<slug>`.** LinkedIn slugs are first-come-first-served
  and rarely match the brand name; the scripts trust the slug you pass and land on
  whoever owns it. Resolve it from `search_companies` or a person's
  `currentCompany` first. Same for `companyId` — an invalid one makes LinkedIn
  silently drop the filter and return `total: 0`, which is indistinguishable from
  a company with no openings.
- **Disambiguate locations through `suggest_locations`** and pass the `geoUrn`
  rather than free text, whenever the place name is ambiguous.
- **Writes are serial and explicitly approved.** Confirm the echoed target
  (`recipient`, `recipientResolved`, the parsed `publicId`) before trusting a
  send, and rely on the idempotent statuses (`already_connected`, `pending`,
  `already_reacted`, `not_following`) instead of re-acting.
- **LinkedIn enforces usage limits and flags accounts that exceed them.** Reads
  can run concurrently but keep the fan-out modest, pace the writes, and remember
  the account at risk is the user's real one.
