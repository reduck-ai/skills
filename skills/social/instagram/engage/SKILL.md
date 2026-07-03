---
name: instagram
description: |
  Read and act on Instagram through saved Reduck scripts. Use when the user
  wants anything from Instagram: a profile's stats or bio, a user's posts or
  reels, a post's comments, followers/following lists, their own home feed or
  DM inbox, reading a conversation — or, on explicit approval, acting: send a
  DM, share a post via DM, comment, follow/unfollow. Triggers: "get <user>'s
  Instagram profile/posts/followers", "comments on this post/reel", "my
  Instagram DMs/feed", "DM <user> on Instagram", "follow/unfollow <user>".
  NOT for: content search/discovery by topic or hashtag (no search brick —
  seed by username or post URL), posting media, or Stories. Needs the reduck
  base plugin.
license: Complete terms in LICENSE
---

# Instagram

Reduck scripts that turn Instagram flows into callable building blocks. Each
script below is a pointer — read its contract (`read_script`, `handle: reduck`)
for the exact args and output. All but `get_profile` are `loggedIn`, so they
need an Instagram session exposed via `reduck local --cookies` (see the `reduck`
skill for the device lifecycle). **Run them local-headed** — the only setup
with any run history; the managed/cloud browser is unproven here, and
Instagram is aggressive about bot detection.

Run history is uneven: the main reads are proven, thin ones are flagged
inline, and the write scripts have **no recorded runs on their current
version** — treat a first write as a live test and verify its echoed result.
Writes are marked **WRITE** — they act under the logged-in account; run them
only on explicit human approval, keep them serial, and confirm the resolved
target (echoed `username`) before trusting an action.

## Keys and conventions

- `username` — handle without the `@` (e.g. `natgeo`).
- `shortcode` / `code` — the X in `instagram.com/p/X/` or `/reel/X/`; the join
  key between posts, comments, and shares.
- `pk` / `user_id` — Instagram's stable numeric id, returned as a string.
- Timestamps: `taken_at` / `created_at` are epoch **seconds**; DM timestamps
  are **microsecond** epochs (each DM script also returns an ISO `date`).
- `media_type`: 1 = image, 2 = video, 8 = carousel.
- Private accounts: reads beyond `get_profile` only work if the logged-in
  account follows them.

## Scripts

All under `reduck/instagram.com/<slug>`.

**Profiles & content (read).**

- `get_profile` — `(username)` → username, user_id, full_name, biography,
  followers/following/posts counts, is_verified, is_private, is_business,
  category, external_url, profile_pic_url. The only script that works logged
  out; always the first call — it yields `user_id` and tells you whether the
  account is private before you spend deeper calls.
- `get_user_posts` — `(username, count default 25)` → posts newest first (code,
  url, taken_at, media_type, caption, like/comment counts, images, video_url,
  tagged_users, caption_mentions, coauthors, sponsor_tags,
  is_paid_partnership). Gotcha: `view_count` is always null here — use
  `get_user_reels` for play counts.
- `get_user_reels` — `(username, count default 0 = all)` → reels (pk, code,
  url, taken_at, caption, thumbnail, video_url, like/play/comment counts,
  video_duration). The play-count source. *Thin run history (1/2).*
- `get_post_comments` — `(code, count default 12)` → the post's caption +
  counts and its preview comments (text, user, verified, created_at,
  like_count, reply_count). Gotcha: only the comments Instagram renders by
  default — not the full thread; the first page is ranked (verified peers
  first), so raw fan sentiment sits deeper than this brick reaches.
- `get_feed` — `(count default 12)` → your own home (For You) feed: post id,
  code, url, author (username, full_name, is_verified), caption, counts,
  taken_at. What the logged-in account sees, not a public read. *Thin run
  history (1/2).*

**Social graph (read).**

- `get_followers` — `(username, count default 50, 0 = all)` → total `count`,
  `has_more`, and followers (pk, username, full_name, is_private, is_verified,
  profile_pic_url).
- `get_following` — same contract, the accounts the user follows.
- Gotcha (both): Instagram serves the full list only for the logged-in account
  or accounts it follows; for anyone else you get the total `count` but the
  name list is capped to the on-screen preview, then `has_more` flips false —
  a short list on a big account is the cap, not the data.

**DMs.** `thread_id` from `get_inbox` is the join key into a conversation.

- `get_inbox` — `(count default 20, 0 = all)` → count, unseen_count, threads
  (thread_id, title, users, is_group, unread, last_activity ISO,
  last_message with sent_by_me/date/type/text). Gotcha: `last_message.text` is
  null for non-text items — read `type` (clip, media, action_log…).
- `get_dm_messages` — `(thread_id, count default 50, 0 = whole conversation)`
  → messages oldest→newest (sent_by_me, sender, type, text, date ISO). Gotcha:
  `sender` is null for your own messages (`sent_by_me` is the signal). *Mixed
  run history (3/6).*
- `send_message` — **WRITE** — `(username, message)` → sends a text DM; returns
  message_id, timestamp_ms, and `notice` (recipient-side restriction banner if
  one rendered). Gotcha: `notice` may lag the server push — null does not
  guarantee delivery.
- `share_post` — **WRITE** — `(shortcode, username)` → shares a post or reel
  into a DM; returns the `thread_key` it landed in. Fails loudly if the
  recipient handle isn't found in search.

**Act (WRITE).** None of the five write scripts (these three plus
`send_message` / `share_post` above) has a recorded run on its current
version — validated by contract, not by history.

- `follow_user` — `(username)` → following, outgoing_request, followed_by,
  user_id. `outgoing_request: true` means a pending request to a private
  account. Fails if there's no Follow button (already following/requested).
- `unfollow_user` — `(username)` → same shape, `following: false` on success;
  also withdraws a pending request to a private account. Fails loudly if you
  weren't following them.
- `write_comment` — `(shortcode, comment)` → posts a real public comment;
  returns the server-assigned `comment_id`.

## Usage notes

- **No discovery brick.** There is no user/hashtag/topic search — every flow
  starts from a known handle or post URL. To discover, either use
  `reduck/google.com/search_site` with `site:instagram.com <topic>`, or pivot
  through a seed account's graph (`get_followers` / `get_following`) and post
  audiences (`get_post_comments`).
- Chain by key: `get_profile` → `get_user_posts`/`get_user_reels` (username) →
  `get_post_comments` (code) → `write_comment`/`share_post` (shortcode);
  `get_inbox` → `get_dm_messages` (thread_id) → reply with `send_message`
  (username).
- Keep read fan-out modest and writes strictly serial — Instagram soft-blocks
  aggressive automation, and the account at risk is the user's real one.
