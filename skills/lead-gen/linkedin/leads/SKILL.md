---
name: linkedin-leads
description: |
  Prospect, qualify, and act on leads from LinkedIn activity. Use when the user
  wants to find who is posting or engaging on a topic, build a lead list from a
  post's reactors or commenters, qualify the resulting profiles/companies, and —
  on a human-approved shortlist — reach out or engage: connection request,
  message, post reaction/comment/reply, repost, unfollow. Seeds leads three ways
  — native people search, company search, or post discovery — pulls each post's
  content + engaged audience, enriches the promising ones, and can read the
  classic messaging inbox. Optional Sales Navigator path when the user has a paid
  seat. Writes run only on an approved shortlist, never the raw pool.
license: Complete terms in LICENSE
---

# LinkedIn leads

Reduck scripts that turn LinkedIn flows into callable building blocks. Each script
below is a pointer — read its contract (`read_script`) for the exact args and
output. They are `loggedIn`, so they need a LinkedIn session exposed via
`reduck local --cookies` (see the `reduck` skill for the bridge lifecycle and how
to run a script).

Every pointer below is a script with a proven run history (>50% success on its
current version); prefer them over the unproven variants. Where a script only
works under a specific browser setup, that's flagged inline — honor it. Writes are
marked **WRITE** — they act under the logged-in account; run them only on a
human-approved shortlist, never the raw pool, and confirm the resolved target
before trusting an action.

## Scripts

**Discover — seed the lead pool.**

- `@reduck/google.com/search_site` — `(query, limit)` → search-result URLs. Used to run `site:linkedin.com/posts <topic>` against Google (not LinkedIn search): a real recency filter and no LinkedIn rate cap. Yields the post URLs that seed the post-driven path.
- `@reduck/linkedin.com/search_posts` — `(keyword, limit, sortBy: relevance|date_posted)` → posts (url, author name/profile/headline, text, reactions, comments, age). LinkedIn-native post search: the in-platform complement to `search_site`. Use it when you want LinkedIn's own ranking and author headlines in one call; use `search_site` when recency/rate-cap matters more. Either seeds the Engage stage with post URLs + their authors.
- `@reduck/linkedin.com/search_people` — `(keywords, optional title/name/company/school/currentCompanyIds/connectionDegrees/location, 10/page)` → people (name, profile URL, publicId, degree, headline, location, snippet). Criteria targeting for users *without* a Sales Navigator seat (lighter filters than SalesNav). Gotcha: free-tier hides `total` and hits a monthly commercial-use cap; out-of-network results are skipped.
- `@reduck/linkedin.com/search_companies` — `(keywords, optional companySizes[] e.g. "51-200", 10/page)` → companies (name, url, slug, `companyId`, pageType company|showcase|school, industry, location, followers, snippet). Company-first targeting: find accounts by keyword + headcount, then pivot to their jobs/posts/people. The `companyId` is the stable join key into `get_company_jobs` and `get_company_info`. Gotcha: browsing caps at ~100 pages (~1000 companies); `companyId` is null for the whole page if the follow-button list misaligns with the cards; the vertical also surfaces `/school/` pages.

**Engage — per discovered post, who said/engaged with what.**

- `@reduck/linkedin.com/get_post` — `(postUrl)` → the post's content and author. The "what was said / by whom" for a discovered URL.
- `@reduck/linkedin.com/get_post_reactors` — `(postUrl, limit)` → the people who reacted (name + profile link + headline + degree). The engaged audience; the raw lead pool before qualification.
- `@reduck/linkedin.com/get_post_comments` — `(postUrl, maxComments, sort)` → the commenters (name, headline, profileUrl, text, reactions, replies). A higher-intent slice than reactors — they wrote something. Use `sort: "recent"` to reach every comment (the default `relevant` hides low-engagement ones). **Run on your browser, headed, only:** reliable on your browser headed (3/3), fails on the cloud browser (0/3) — start the bridge with a headed session for this one.

**Enrich — shortlist only.**

- `@reduck/linkedin.com/get_profile` — `(profileUrl | member-id link)` → the canonical profile (name, headline, location, About). Resolves a reactor's member-id link to the real profile and is the input the other profile scripts need — always the first enrichment call.
- `@reduck/linkedin.com/get_profile_info` — `(publicId)` → the structured top-card metadata in one call: connection `degree`, `currentCompany`, `education` chip, `followers`/`connections`, and `contactInfoAvailable`. Complements `get_profile` (which carries the About prose but not these chips) — use it for a fast qualification read without the separate experience/education/company calls.
- `@reduck/linkedin.com/get_profile_experience` — `(profileUrl)` → roles / tenure. Confirms the person is who the post suggested (title, seniority, current company).
- `@reduck/linkedin.com/get_profile_education` — `(profileUrl)` → schools / degrees. A qualification signal (alma mater, field of study) for the shortlist.
- `@reduck/linkedin.com/get_profile_posts` — `(profileUrl)` → the person's own recent posts. A strong personalization signal (what they're working on / care about) and an activity check before a human spends time on them.
- `@reduck/linkedin.com/get_profile_comments` — `(publicId, count)` → the comments the person has left on posts, with the post each was made on. What they engage with — a complementary personalization + activity signal.
- `@reduck/linkedin.com/get_company_info` — `(companyUrl | name)` → firmographics (size, industry) and the numeric `companyId`. Sizes the account behind a qualified person, and is the id source for `get_company_jobs`.

**Company / account angle (optional).** Pivot from a person to their account, or target accounts directly. Seed with `search_companies` (above) or `get_company_info` for the `companyId`.

- `@reduck/linkedin.com/get_company_jobs` — `(companyId — numeric, from get_company_info/search_companies; optional keywords/geoId, 25/page)` → the company's open postings (jobId, title, location, postedAgo, easyApply, url). Worldwide by default (geoId 92000000; the UI's own default silently restricts to the viewer's country). Gotcha: slugs are rejected, and an **invalid id makes LinkedIn silently drop the filter and return `total: 0`** — indistinguishable from a company with no openings, so only pass ids that came from the company scripts.
- `@reduck/linkedin.com/get_company_posts` — `(company — URL or slug, count ≤50, default 10)` → the company's most recent posts (activityId, url, text, postedAt ISO, age, isRepost, reactions, comments, reposts), newest first. The account's own voice — a firmographic/positioning read, and a source of post URLs to feed back into Engage. Gotcha: `postedAt` for a repost is when the company reposted, not the original time; assumes an English UI. **Never guess the slug from the brand name** — LinkedIn `/company/<slug>` is first-come-first-served and rarely matches (e.g. `sharpstone` resolves to an unrelated Oklahoma IT firm, not the French VC whose real slug is `sharpstone-advisory-capital`). The script trusts the slug you give it and silently lands on whatever page owns it. Resolve the exact slug from a known-good source first: a person's `get_profile` / `get_profile_info` `currentCompany` (carries the real page URL), or `search_companies` (which returns the canonical `slug` + `companyId`). Same caveat for `get_company_info`.

**Inbox — read existing conversations (read-only).** Classic LinkedIn messaging, **not** Sales Navigator.

- `@reduck/linkedin.com/list_inbox` — `(limit default 20, unreadOnly)` → conversations (threadUrl, threadId, participants name/profileUrl/degree, unreadCount, lastActivityAt, lastMessage text/at/fromSelf/subject). Where a reply or follow-up already lives; returns the first inbox page only.
- `@reduck/linkedin.com/get_thread` — `(threadUrl — from list_inbox)` → participants + messages (from, fromSelf, text, time, subject), chronological. Read the full exchange before drafting a reply. Returns the recent page only.
- `@reduck/linkedin.com/get_received_invitations` — `(limit default 100)` → the pending connection requests *you've received* (inviter name, headline, profileUrl, mutual-connection note, and `type`: person|event|newsletter|page). The triage surface before `accept_invitation` / `ignore_invitation` — read who's waiting, then act on a person-by-person basis.

**Own-account analytics (your own footprint, not leads).** Measure the logged-in account's own reach — track how your own outreach/content is performing. Off the prospecting path; both are owner-only and read-only.

- `@reduck/linkedin.com/get_dashboard` — `()` → your own analytics overview (post impressions, total followers, profile viewers, search appearances; newsletter rows when present): one entry per tile with `value`, `changePercent`, `direction` (up/down/flat), and the comparison window. Requires login; English UI assumed.
- `@reduck/linkedin.com/get_post_analytics` — `(postUrl — YOUR OWN post: a urn from get_profile_posts, a permalink, or a bare activity id)` → that post's analytics: impressions, membersReached, profileViewers, followersGained, the engagement breakdown (reactions/comments/reposts/saves/sends, linkVisits) and `topDemographics` per category (location, seniority, company size, industry, job title, company). **Owner-only** — throws on posts you didn't author; pairs with `get_profile_posts` (pass the urn it returns). Use `get_post` for public counts on anyone's post.

**Sales Navigator — direct targeting (requires a paid seat).** When the user has a Sales Navigator seat, this is the direct-targeting path: search by structured criteria and skip the post-discovery hop entirely. Skip this block only if they have no seat — the post-driven path works without one.

- `@reduck/linkedin.com/sales_navigator_search_people` — `(filters: keywords/title/geography/seniority/function/company-size/tenure, limit)` → people matching structured criteria, with richer filters than native `search_people`. The main direct-targeting entry point; feed its results straight to Qualify/Enrich.
- `@reduck/linkedin.com/sales_navigator_search_accounts` — `(filters, limit)` → companies matching structured criteria. Account-first targeting.
- `@reduck/linkedin.com/sales_navigator_get_lead` — `(leadId — from sales_navigator_search_people)` → the full lead profile: fullName, headline, summary, degree, location, the classic LinkedIn profile URL, full position history, saved-list status, and contact info *when the lead is unlocked for the seat*. The enrich step after a SalesNav search.
- `@reduck/linkedin.com/sales_navigator_get_account` — `(accountId — from sales_navigator_search_accounts, or a companyUrn off search_people)` → the company account: description, industry, type, specialties, website, founded year, HQ/locations, revenue range, employee count + growth, headcount history, median tenure, and spotlight employees (each with a `leadId` to pivot back to `get_lead`).
- `@reduck/linkedin.com/sales_navigator_list_lead_lists` — `()` → the viewer's saved-lead lists (id — the join key for saving, name, description, source MANUAL|SYSTEM|CRM, role, entityCount, timestamps), most-recently-modified first. Returns the first page + the exact total so truncation is visible.
- `@reduck/linkedin.com/sales_navigator_get_lead_list` — `(list id — from list_lead_lists, start/count default 25)` → the leads saved inside a list (salesProfileUrn — feeds `save_lead_to_list`/`get_lead`, salesLeadUrl, name, degree, geoRegion, current title/company, dateAddedToListAt, crmStatus), newest-added first, with the exact total.
- `@reduck/linkedin.com/sales_navigator_save_lead_to_list` — **WRITE** — `(salesProfile urns — from search_people/get_lead_list/get_lead, list ids — from list_lead_lists)` → saves one or more leads into one or more *manual* lists (bulkSaveByMembers). Per-(lead,list) result: `CONFLICT` = already in that list, anything else = saved. Manual lists you own only (not system/auto lists).
- `@reduck/linkedin.com/sales_navigator_get_inbox` — `(count, filter INBOX|UNREAD|ARCHIVED, pageStartsAt)` → the latest SalesNav inbox conversations: threads (threadId, unread + unreadCount, archived, totalMessageCount, the other participants with salesLeadUrl, and the last message with body/subject/type/deliveredAt/direction). Paginate newest→oldest via the returned `nextPageStartsAt`. Distinct from classic `list_inbox`.
- `@reduck/linkedin.com/sales_navigator_get_thread` — `(threadId — from get_inbox, messageCount)` → the full SalesNav conversation: participants, totalMessageCount, and every message chronologically (body, subject for InMail, type MESSAGE|INMAIL, deliveredAt, attachments, direction sent|received). If `returnedCount < totalMessageCount`, raise `messageCount`.
- `@reduck/linkedin.com/sales_navigator_send_message` — **WRITE** — `(recipientName, body)` → sends a regular Sales Navigator message (no InMail/subject/credit) to a 1st/2nd-degree connection found by name in the SalesNav inbox composer. Out-of-network leads aren't reachable here (they need InMail from the lead page). Confirm the recipient with the echoed `recipientResolved` before trusting the send.

**Hiring signal (optional, off the main leads path).** A company actively hiring for a role is a buying/expansion signal; use only when hiring intent is the targeting criterion.

- `@reduck/linkedin.com/search_jobs` — `(keywords, optional location/datePosted/workplaceType/sort, 25/page)` → job postings (jobId, title, company, location, postedAgo, url). Worldwide by default. (For one known company's openings, use `get_company_jobs` instead — it filters by `companyId`.)
- `@reduck/linkedin.com/get_job` — `(jobId)` → the full posting plus company firmographics. From a hiring company, pivot to its people via `search_people` (company filter) or size it via `get_company_info`.

**Act — outreach + engagement (WRITE, shortlist only).** These take real actions under the logged-in account. Run only on a human-approved shortlist, never the raw pool; confirm the resolved target before trusting the send; lean on each script's idempotent status (e.g. `already_connected`, `already_reacted`) instead of re-acting.

- `@reduck/linkedin.com/connect` — **WRITE** — `(profileUrl — the /in/<publicId> form)` → sends a connection request *without* a note. Returns `status`: `sent` | `pending` (already outstanding) | `already_connected` | `no_connect_cta` | `email_required`. Gotcha: only the top-card Connect is handled — influencers/public figures who show Follow as the primary action (Connect buried under "More") return `no_connect_cta`. (Need a note? `connect_with_note` exists but has a weaker run history.)
- `@reduck/linkedin.com/send_message` — **WRITE** — `(message, + threadUrl OR recipient)` → classic messaging (**not** Sales Navigator). Reply in an existing thread (`threadUrl` from `list_inbox`) or start one by display `recipient` name (first typeahead match — a name isn't a unique key, so confirm the returned `recipient`). 1st-degree / open-profile only; InMail is a separate paid flow.
- `@reduck/linkedin.com/react_post` — **WRITE** — `(postUrl, reaction default "like")` → likes the main post. Idempotent: returns `already_reacted` if you already did. v1 supports Like only; scopes to the main post, not per-comment reactions.
- `@reduck/linkedin.com/comment_post` — **WRITE** — `(postUrl, comment)` → posts a real public top-level comment. Returns `posted` + the new `commentUrn` (feeds `reply_comment`).
- `@reduck/linkedin.com/reply_comment` — **WRITE** — `(postUrl, commentUrn — from get_post_comments/comment_post, reply)` → posts a public reply to a specific comment. The target comment must already be loaded on the page (not behind a "load more" / "see previous replies" loader); the reply box's auto-@mention is replaced with your text.
- `@reduck/linkedin.com/repost` — **WRITE** — `(postUrl)` → instant repost to your feed (no added thoughts; quote-repost is a separate flow). Returns `reposted`. To undo, delete the repost from your own activity.
- `@reduck/linkedin.com/unfollow` — **WRITE** — `(profileUrl)` → stops following a member. Idempotent: returns `not_following` if you weren't. Note: unfollowing is not the same as disconnecting (you stay 1st-degree).
- `@reduck/linkedin.com/connect_with_note` — **WRITE** — `(profileUrl, message ≤200 chars)` → connection request *with* a personal note (higher accept rate than the note-free `connect`). Returns `status`: `sent` | `already_connected` | `pending` | `no_quota` | `no_connect_cta` | `failed`. Fails fast when the free-tier monthly note quota is exhausted (`no_quota`) or the profile isn't connectable.
- `@reduck/linkedin.com/follow` — **WRITE** — `(profileUrl)` → follows a member without connecting (works whether Follow is the top-card action or buried under "More"). Idempotent: `already_following` / `no_follow_cta`. A lighter-touch warm-up than a connection request.
- `@reduck/linkedin.com/withdraw` — **WRITE** — `(profileUrl)` → withdraws a *pending sent* invitation. Idempotent: returns `not_pending` if none outstanding. Pipeline cleanup. Gotcha: after withdrawing, LinkedIn blocks resending to that person for ~3 weeks; withdrawing does **not** unfollow.
- `@reduck/linkedin.com/accept_invitation` — **WRITE** — `(name — inviter's display name, from get_received_invitations)` → accepts a *received* invitation. Homonym-guarded: ≥2 matching pending invitations → throws rather than guess. Confirm with the returned `recipientResolved`.
- `@reduck/linkedin.com/ignore_invitation` — **WRITE** — `(name — inviter's display name)` → declines a *received* invitation. Same homonym guard; ignoring is not easily reversible, so triage from `get_received_invitations` first.

## System prompt

Orchestrate the scripts in stages; stop at the first stage that answers the
user's question — don't enrich or act on what you won't use.

1. **Discover** — choose the seed by what the user has and wants:
   - **Default (no seat)** — post-driven: `search_site` over
     `site:linkedin.com/posts` plus the topic, newest first, scoped to the time
     window asked for. (Google, not LinkedIn search: a real recency filter and no
     LinkedIn rate cap.) Or `search_posts` for LinkedIn-native ranking + author
     headlines in one call when recency matters less. Either yields post URLs for
     Engage. The full flow works end-to-end without any subscription.
   - **Criteria targeting (no seat needed)** — `search_people` seeds profiles by
     title/company/geography; `search_companies` seeds accounts by keyword +
     headcount (then pivot to people, jobs, or posts). Skip Engage, go straight to
     Qualify.
   - **With a Sales Navigator seat** — direct targeting:
     `sales_navigator_search_people` (or `_accounts` for account-first) by
     structured criteria, bypassing posts entirely — skip Engage and go straight
     to Qualify/Enrich. Never assume the user has Sales Navigator — only take this
     path if they have it; otherwise stay on a path above.
   - *Hiring intent (any path):* `search_jobs` → `get_job`, or for one known
     account `get_company_jobs` (needs a `companyId`); then pivot to people via
     `search_people` (company filter).
2. **Engage** (post-driven path only) — per post, `get_post` for the
   content/author, then the engaged audience: `get_post_reactors` (broad) and/or
   `get_post_comments` (higher-intent — they wrote something; run on your browser, headed).
   A post too fresh to have engagement yields nothing here — that's expected,
   not a failure.
3. **Qualify** — score the people as leads (the `icp` skill, if installed, is the
   rubric; otherwise apply the user's stated criteria). Keep only the shortlist
   worth a human's attention; a viral post's reactions are mostly noise.
4. **Enrich** — shortlist only: `get_profile` first (it resolves a reactor's
   member-id link to the canonical profile and is the input the other profile
   scripts need), then `get_profile_experience` to confirm the person,
   `get_profile_education` for background, `get_profile_posts` / `get_profile_comments`
   for the personalization hook, `get_company_info` to size the account, and
   `get_company_jobs` / `get_company_posts` for the account's hiring + voice. Stop
   as soon as the verdict is decided.
5. **Act** (optional, WRITE — human-approved shortlist only) — take the action the
   user asked for, never on the raw pool:
   - *Outreach:* `connect` (request, no note) or `connect_with_note` (personal note, higher accept rate, watch the free-tier `no_quota`) → once connected, `send_message`
     (classic — reply via `list_inbox`/`get_thread`, or start by name), or
     `sales_navigator_send_message` on a SalesNav seat. `follow` is the lighter-touch alternative when a connection request is too much.
   - *Warm/nurture on the feed:* `react_post`, `comment_post`, `reply_comment`
     (needs a `commentUrn`), `repost`.
   - *Inbound triage:* `get_received_invitations` to see who's requested you, then `accept_invitation` / `ignore_invitation` by name (homonym-guarded).
   - *Maintenance:* `unfollow`, or `withdraw` to retract a pending sent invitation (cleans the pipeline; blocks resending for ~3 weeks).
   Always confirm the resolved target (echoed `recipient`/`recipientResolved`,
   parsed `publicId`) before trusting a send, and rely on the idempotent statuses
   (`already_connected`, `pending`, `already_reacted`, `not_following`) rather than
   re-acting. Keep writes serial and explicitly approved — a wide fan-out of
   actions is both a reliability and an account-safety risk.

Deliver per lead: the verdict and the one signal that earned it. Run the per-post
and per-lead read steps concurrently, but keep concurrency modest — a wide browser
fan-out is its own failure mode — and keep writes serial.
