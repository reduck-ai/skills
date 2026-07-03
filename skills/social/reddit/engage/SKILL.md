---
name: reddit
description: |
  Read, search, and act on Reddit through saved Reduck scripts. Use when the
  user wants anything from Reddit: what's trending, a subreddit's threads,
  rules or mods, a full thread with comments, a user's profile and history,
  topic search across Reddit or inside one subreddit, pain-point mining on a
  community — or, on explicit approval, acting: post a thread, crosspost,
  comment or reply, edit/delete own content, vote, save, join/leave a
  subreddit, follow a user, send a DM. Triggers: "what does r/<sub> say
  about X", "search Reddit for X", "get this thread's comments", "find pain
  points in r/<sub>", "post/comment/reply on Reddit", "DM <user> on Reddit".
  NOT for: link/image posts (text posts only), reading DM inboxes (send
  only), or moderation actions. Needs the reduck base plugin.
license: Complete terms in LICENSE
---

# Reddit

Reduck scripts that turn Reddit flows into callable building blocks. Each
script is a pointer — read its contract (`read_script`, `handle: reduck`) for
exact args and output. The five discovery reads (`get_trending`,
`get_subreddit_threads`, `get_thread`, `search_reddit`, `search_subreddit`)
work logged out; everything else is `loggedIn` and acts as whatever account
is in the real Chrome cookie jar — expose it via `reduck local --cookies`
(see the `reduck` skill for the device lifecycle) and run local-headed.

Writes are marked **WRITE** — they publish under the user's real account.
Run them only on explicit human approval, keep them strictly serial, and
verify the echoed result (`id`/`permalink`/`url`).

## Keys and conventions

- `subreddit` / `username` — with or without the `r/` / `u/` prefix.
- Post URL — `/r/<sub>/comments/<postid>/...`, full or path; `<postid>` is
  the base36 id `get_thread` also accepts directly.
- Comment permalink — `/r/<sub>/comments/<postid>/comment/<commentid>/`; the
  join key between a comment and every per-comment action (reply, edit,
  delete, vote).
- New posts come back as a fullname (`t3_<id>`) plus URL.
- Membership/follow/save toggles are idempotent: `changed: false` means it
  was already in the requested state.

## Discover & read

- `get_trending` — `(feed popular|all, sort?, limit)` → cross-Reddit feed:
  url, title, subreddit, author, score, comments, date.
- `search_reddit` — `(topic, sort, time, limit)` → posts across all of
  Reddit; the way to find which subreddits discuss a topic.
- `search_subreddit` — `(subreddit, topic, sort, time, limit)` → same shape
  inside one community. `limit` paginates via the site's infinite scroll but
  Reddit caps search at ~100 results — beyond that, narrow with `time` or
  the query instead.
- `get_subreddit_threads` — `(subreddit, sort best|hot|new|top|rising,
  limit?, since?)` → a community's threads. `new` is chronological and takes
  `since` (ISO date or `24h`/`7d`/`2w`); `top` takes a `time` window; the
  ranked sorts paginate by `limit` only.
- `get_subreddit_info` — `(subreddit)` → title, description, activity
  counts, created, rules, full moderator list. Banned/private subs return a
  status instead of throwing.
- `get_thread` — `(url | id, sort?, all_comments?)` → title, OP text, score,
  and the comment tree (author, body, score, depth). Compare `num_comments`
  vs `total_comments` to detect truncation; `all_comments: true` expands
  every "more replies" (slow on big threads).
- `get_user` — `(username, limit)` → profile, karma, reddit_age, and recent
  posts + comments. The qualification brick before any outreach.
- `find_pain_points` — `(subreddit, topic, criteria, limit, time?)` → the
  composite research brick: searches the sub, keeps threads whose title + OP
  match plain-language `criteria`, and summarises each match's pain points.
  Criteria filter on title + OP only — the summary sees the full thread.

## Act (WRITE)

**Publish.**

- `submit_post` — `(subreddit, title, body)` → new post fullname + URL. Text
  posts only; some subs require a flair and block the post — it fails loud.
- `crosspost` — `(source_url, subreddit, title?)` → repost into another sub,
  keeping the backlink. Fails loud where reposting is disabled.
- `post_comment` — `(url, text)` → top-level comment on a post; returns id +
  permalink.
- `reply_comment` — `(permalink, text)` → reply to a comment at any depth;
  returns the new reply's id, permalink, depth.

**Own content.** Only work on the logged-in account's content.

- `edit_post` — `(url, body)` — replaces the body entirely; titles can't be
  edited on Reddit.
- `edit_comment` — `(permalink, text)` — full replacement.
- `delete_post` / `delete_comment` — irreversible; deleted comments leave
  orphaned replies under `[deleted]`.

**Engage.**

- `vote` — `(url | permalink, direction up|down|clear)` → idempotent.
  Gotcha: you can't downvote or clear the vote on your OWN post — Reddit
  forces the author's upvote and reverts the change.
- `save_post` / `unsave_post` — `(url)` → private, visible only to you.
- `join_subreddit` / `leave_subreddit` — `(subreddit)`.
- `follow_user` / `unfollow_user` — `(username)`.
- `send_dm` — `(to, subject, message)` → Reddit requires a `subject` but
  never shows it in the conversation. Fails for recipients who don't accept
  DMs. Send-only — there is no inbox-reading brick.

## Usage notes

- Chain by key: `search_reddit` (find the subs) → `search_subreddit` /
  `get_subreddit_threads` (find the threads) → `get_thread` (read the
  conversation) → `get_user` (qualify an author) → engage
  (`reply_comment` / `post_comment` / `send_dm`) on an approved shortlist.
- Read the target sub's rules (`get_subreddit_info`) before any write —
  flair requirements and repost bans are the two loud failure modes.
- Run scripts strictly one at a time — reads included. The local device
  handles a single browser session; parallel `run_script` calls fail with
  504/worker-socket timeouts and can wedge the device.
- Rate limit: bursts of chained actions trigger `Too many requests`; space
  writes out and back off ~3 minutes if it fires.
- `r/test` allows posts and crossposts with no flair — use it to validate a
  write flow before touching a real community.
