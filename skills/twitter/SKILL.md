---
name: twitter
description: |
    Read, search, and act on Twitter/X. Use for a profile, a user's posts or
    replies, tweet search, a tweet and its conversation, who reposted it,
    followers or following, your own feed, mentions, DMs and post analytics — or,
    on explicit approval, acting: post a tweet or thread, reply, quote, retweet,
    like, bookmark, DM, follow, mute, block.
    NOT for a tweet's likers — X made likes private in 2024.
---

# Requirements

- **Reduck MCP, with the browser extension installed.** If it isn't set up, follow the instructions at [start.reduck.ai](https://start.reduck.ai/).

**Read**

- **`reduck/x.com/get_user_info`**
- **`reduck/x.com/get_user_posts`**
- **`reduck/x.com/get_user_replies`**
- **`reduck/x.com/get_tweet`**
- **`reduck/x.com/search_tweets`**
- **`reduck/x.com/get_reposters`**
- **`reduck/x.com/get_follows`**
- **`reduck/x.com/get_personal_feed`**
- **`reduck/x.com/get_mentions`**
- **`reduck/x.com/get_post_analytics`**

**DMs**

- **`reduck/x.com/get_inbox`**
- **`reduck/x.com/get_messages`**
- **`reduck/x.com/send_dm`** — WRITE

**Act** — WRITE

- **`reduck/x.com/post_tweet`**
- **`reduck/x.com/post_thread`**
- **`reduck/x.com/reply_to_tweet`**
- **`reduck/x.com/quote_tweet`**
- **`reduck/x.com/retweet`**
- **`reduck/x.com/unretweet`**
- **`reduck/x.com/like_tweet`**
- **`reduck/x.com/unlike_tweet`**
- **`reduck/x.com/bookmark_tweet`**
- **`reduck/x.com/unbookmark_tweet`**
- **`reduck/x.com/delete_tweet`**
- **`reduck/x.com/follow_user`**
- **`reduck/x.com/unfollow_user`**
- **`reduck/x.com/mute_user`**
- **`reduck/x.com/unmute_user`**
- **`reduck/x.com/block_user`**
- **`reduck/x.com/unblock_user`**

Read their contracts live with `read_script` Reduck MCP.

Every one runs as the X account signed into your paired browser — reads included.
There is no logged-out route.

# Keys

- `handle` — without the `@` (the `@` form works too, but bare always does).
- `tweet_url` — `https://x.com/<handle>/status/<id>`; the numeric `<id>` is the
  join key everywhere.
- Most reads return the same canonical tweet record (id, url, author, text,
  created_at, counts, `is_retweet`, `is_quote`, `in_reply_to`), so results from
  different scripts join and dedupe on `id` directly.

# The flow

Discover with `search_tweets` (full X operator syntax: `from:`, `min_faves:`,
`since:`/`until:`, quoted phrases) → deepen with `get_tweet` for a conversation or
`get_user_posts` / `get_user_replies` for an account → pivot to the audience with
`get_reposters` or `get_follows` → act on an approved shortlist.

`get_tweet` returns the focal tweet plus **every other tweet on the conversation
page** — the ancestors above it as well as the replies below. Use `in_reply_to` to
tell them apart and rebuild the thread; the array is not filtered to descendants.

# Rules

- **Confirm the exact arguments with the user before any script that changes
  state** — posting, replying, deleting, following, muting, blocking, DMing. Show
  the literal text and the resolved target and get a go-ahead. These are visible
  to others and hard to reverse; a general "post about X" is not approval for a
  particular tweet.
- **`get_tweet` needs the same confirmation**, even though it only reads. Show the
  URL you're about to fetch: against the wrong one it surfaces the wrong thread.
- **Run scripts strictly one at a time, reads included.** The paired browser
  drives a single session; parallel runs time out and can wedge it. X also
  throttles aggressive pagination, and the account at risk is the user's real one.
- **Trust the echoed state, not the attempt.** Writes report `was_liked` /
  `was_retweeted` / `was_following` and are idempotent, so read those instead of
  re-acting. Where a script returns `verified_on_page` and `account_used`, check
  both — they confirm the change is really visible and that it happened under the
  account you meant.
- **Every read is a sample, not an inventory.** `search_tweets` on `top` is a
  ranked sample, `get_reposters` caps a few hundred deep on high-repost posts, and
  the timeline scripts stop where X starts throttling. `get_tweet`'s
  `complete: true` is still a floor — replies behind a "Show more replies" or
  spam cursor are never expanded.
- DM scripts can hit X's "Enter Passcode" screen on a fresh session; pass the
  account's 4-digit `pin`. It's the user's secret — ask, never guess.
- `get_post_analytics` is owner-only, its large counts are abbreviated and so
  approximate, and X throws a transient Retry error — re-run on failure.
- On `get_personal_feed`, a retweet's `id` is the wrapper; join through
  `retweeted_tweet.id` to reach the original.
