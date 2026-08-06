---
name: facebook-leads
description: |
    Prospect and qualify leads from Facebook Group and Page activity. Use to find
    who is active in a niche community, build a lead list from a group's members
    or a post's commenters, or surface a competitor Page's top content and its
    engaged audience. NOT for writes by default — joining a group, posting, and
    friend requests are an opt-in step the user must ask for.
---

# Requirements

- **Reduck MCP, with the browser extension installed.** If it isn't set up, follow the instructions at [start.reduck.ai](https://start.reduck.ai/).

**Read**

- **`reduck/facebook.com/search_groups`**
- **`reduck/facebook.com/list_posts`**
- **`reduck/facebook.com/get_post_engagement`**
- **`reduck/facebook.com/list_group_members`**
- **`reduck/facebook.com/get_profile`**

**Growth** — WRITE, opt-in only

- **`reduck/facebook.com/join_group`**
- **`reduck/facebook.com/post_to_group`**
- **`reduck/facebook.com/add_friend`**

Read their contracts live with `read_script` Reduck MCP.

They run as the Facebook account signed into your paired browser.

# The flow

Stop at the first stage that answers the question.

1. **Discover** — `search_groups` over the niche, then keep only the groups that
   are alive (`members` against `postsPerDay`). If the user already named a group
   or a competitor Page, skip straight to Engage with its URL.
2. **Engage** — `list_posts` on the feed (it reads groups and Pages alike), rank
   by reactions and comments, then `get_post_engagement` on the top threads for
   the commenters. `list_group_members` gives the standing roster when the
   question is about the community rather than one post.
3. **Qualify** — Facebook's signal is thinner than LinkedIn's. The member
   `subtitle` (Admin badge, bio fragment, mutual friends, join recency) and the
   fact someone commented on a relevant thread are the best cues; an Admin who
   also commented on the target topic outranks a silent member.
4. **Enrich** — `get_profile` on the shortlist for the header and intro: profile
   or Page, name, friends / followers, mutual friends, and the intro lines (bio,
   city, work, education for people; description for Pages).

Deliver per lead: the verdict and the one signal that earned it.

# Rules

- **Counts come back as the strings Facebook displays** — `"77,9 K"`, `"11 K"` —
  not integers. Parse before comparing, and don't read an abbreviated total as
  precise.
- **Comment and member lists are samples, not inventories.** Both are
  infinite-scroll, capped by your limit, and comments arrive in Facebook's
  non-deterministic "Most relevant" order — so the same call twice can differ.
- `get_profile`'s intro lines come back as they appear, not sorted into city /
  work / school fields.
- **The three write scripts never fire unless the user explicitly asks to act.**
  They are visible and often irreversible: a friend request can't be quietly
  un-sent, a group post may notify admins. Confirm scope first and respect any
  per-run cap the user sets. `post_to_group` takes `dryRun` to arm the composer
  without publishing — use it to rehearse; its `verified: false` on a real run
  means the post is held for admin approval, not that it failed.
- Keep concurrency modest — a wide fan-out on Facebook triggers rate prompts and
  checkpoints.
