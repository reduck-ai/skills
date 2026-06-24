---
name: facebook-leads
description: |
  Prospect and qualify B2B leads from Facebook Group and Page activity. Use when
  the user wants to find who is active in a niche or community on Facebook, build
  a lead list from a group's members or a post's commenters, or surface a
  competitor Page's top content and its engaged audience. Discovers relevant
  groups, ranks their posts by engagement, pulls members and commenters, then
  qualifies the promising ones from what Facebook exposes. NOT for writes by
  default (joining a group, posting, friend requests) — those are an explicit,
  opt-in growth step the user must ask for.
license: Complete terms in LICENSE
---

# Facebook leads

Reduck scripts that turn Facebook flows into callable building blocks. Each
script below is a pointer — read its contract (`read_script`) for the exact args
and output shape before relying on it. They are all `loggedIn`, so they need a
Facebook session exposed via `reduck local --cookies` (see the `reduck` skill for
the bridge lifecycle and how to run a script).

## Scripts

Read (discovery / qualification):

- `@reduck/facebook.com/search_groups` — `(query, limit)` → groups: `groupId`, `name`, `url`, `privacy`, `members`, `postsPerDay`. Use members + postsPerDay to gauge whether a group is alive before you spend reads on it.
- `@reduck/facebook.com/list_posts` — `(url, limit)` → a **group OR page feed**: `postId`, clean permalink, `author`, `authorUrl`, `reactions`, `comments`, `shares`, `createdTime`, `text`. Reads the Comet feed GraphQL. Rank by reactions/comments to find the threads worth opening.
- `@reduck/facebook.com/get_post_engagement` — `(postUrl, commentLimit)` → `reactions` / `comments` / `shares` plus the commenters. The engaged audience of a single post. ⚠️ `reactionsTotal` is unreliable (can under-read a post `list_posts` saw with thousands of reactions) — trust the commenter list, not that count.
- `@reduck/facebook.com/list_group_members` — `(groupId, limit)` → per member: `name`, `userId`, `profileUrl`, `subtitle` (Admin / bio / mutuals / join-recency). Slug-agnostic. The `subtitle` is the main qualifying signal Facebook gives you.

Write (growth — opt-in only, see below):

- `@reduck/facebook.com/join_group` — `(groupId)` → `joined` / `pending` / `already_member`.
- `@reduck/facebook.com/post_to_group` — `(groupId, message)` → `posted` (may be held for admin approval).
- `@reduck/facebook.com/add_friend` — `(profile url | userId)` → `sent` / `already_pending` / `already_friends` / `not_addable`. Scopes to the header button by profile-owner name (skips suggestion cards).

## System prompt

Orchestrate the read scripts in four stages; stop at the first stage that answers
the user's question — don't enrich what you won't use.

1. **Discover** — `search_groups` over the niche/topic, then keep only groups that
   are actually active (`members` × `postsPerDay`). If the user already named a
   group or competitor Page, skip straight to Engage with its URL.
2. **Engage** — per group/page, `list_posts` on the feed and rank by reactions +
   comments to find the live threads; then `get_post_engagement` on the top posts
   to pull the commenters (the people leaning in). A post too fresh to have
   engagement yields nothing here — expected, not a failure. `list_group_members`
   gives you the standing roster when the question is about the community itself
   rather than a specific post.
3. **Qualify** — score the commenters and members as leads. Facebook's signal is
   thinner than LinkedIn's: the `subtitle` from `list_group_members` (Admin, bio,
   mutuals) and the fact that someone commented on a relevant thread are your best
   cues. Keep only the shortlist worth a human's attention — a busy group's roster
   is mostly noise.
4. **Enrich** — stay within Facebook. The shortlist already carries what Facebook
   exposes: `profileUrl`, the `subtitle` (Admin badge, bio fragment, mutual count,
   how recently they joined), and which thread they engaged on. Cross-reference
   those signals to settle the verdict — e.g. an Admin who also commented on the
   target topic outranks a silent member. There is no `get_profile` on Facebook,
   so deep firmographic enrichment is out of scope for this skill; decide from the
   group-level signal and stop.

Deliver per lead: the verdict and the one signal that earned it (the thread they
commented on, the Admin badge, the mutuals count). Run the per-post and per-member
steps concurrently, but keep concurrency modest — a wide browser fan-out on
Facebook is its own failure mode (rate prompts, checkpoints).

## Growth (writes — opt-in)

The three write scripts (`join_group`, `post_to_group`, `add_friend`) are NOT part
of the leads flow and must never fire unless the user explicitly asks to act.
Typical combos, only on request:

- "join this niche group and post X" → `search_groups` → `join_group` → `post_to_group`.
- "add the most active members of this group" → `list_posts` (rank by reactions) +
  `list_group_members` → `add_friend` on the shortlist.

Writes are visible, often irreversible social actions (a friend request can't be
quietly un-sent; a group post may notify admins). Confirm scope with the user
before sending, and respect any per-run cap they set.
