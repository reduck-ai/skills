---
name: instagram
description: |
    Read and act on Instagram. Use to search accounts or hashtags, pull a
    profile's stats, posts, reels, stories or highlights, read a post's comments
    and their replies, walk follower lists, read your own feed and DMs — or, on
    explicit approval, acting: publish a post, reel or carousel, comment or reply,
    like, save, DM, share a post, follow or unfollow.
    NOT for Stories publishing or reading a private account you don't follow.
---

# Requirements

- **Reduck MCP, with the browser extension installed.** If it isn't set up, follow the instructions at [start.reduck.ai](https://start.reduck.ai/).

**Discover**

- **`reduck/instagram.com/search_users`**
- **`reduck/instagram.com/search_hashtag`**
- **`reduck/instagram.com/get_hashtag_posts`**

**Profiles and content**

- **`reduck/instagram.com/get_profile`**
- **`reduck/instagram.com/get_user_posts`**
- **`reduck/instagram.com/get_user_reels`**
- **`reduck/instagram.com/get_tagged_posts`**
- **`reduck/instagram.com/get_stories`**
- **`reduck/instagram.com/get_highlights`**
- **`reduck/instagram.com/get_post_comments`**
- **`reduck/instagram.com/get_comment_replies`**
- **`reduck/instagram.com/get_feed`**

**Social graph**

- **`reduck/instagram.com/get_followers`**
- **`reduck/instagram.com/get_following`**

**DMs**

- **`reduck/instagram.com/get_inbox`**
- **`reduck/instagram.com/get_dm_messages`**
- **`reduck/instagram.com/send_message`** — WRITE
- **`reduck/instagram.com/share_post`** — WRITE

**Act** — WRITE

- **`reduck/instagram.com/create_post`**
- **`reduck/instagram.com/create_post_carousel`**
- **`reduck/instagram.com/create_reel`**
- **`reduck/instagram.com/delete_post`**
- **`reduck/instagram.com/write_comment`**
- **`reduck/instagram.com/reply_to_comment`**
- **`reduck/instagram.com/like_post`**
- **`reduck/instagram.com/unlike_post`**
- **`reduck/instagram.com/like_comment`**
- **`reduck/instagram.com/unlike_comment`**
- **`reduck/instagram.com/save_post`**
- **`reduck/instagram.com/unsave_post`**
- **`reduck/instagram.com/follow_user`**
- **`reduck/instagram.com/unfollow_user`**

Read their contracts live with `read_script` Reduck MCP.

All but `get_profile` run as the Instagram account signed into your paired
browser.

# Keys

- `username` — the handle without the `@`.
- `shortcode` — the `X` in `instagram.com/p/X/` or `/reel/X/`; the join key
  between posts, comments and shares.
- `user_id` — Instagram's stable numeric id, returned as a string by
  `get_profile`, and what the stories, highlights and tagged-posts scripts take.
- `thread_id` — from `get_inbox`, the join key into a conversation.

# The flow

Chain by key: `search_users` or `search_hashtag` / `get_hashtag_posts` to
discover → `get_profile` (yields `user_id`, and tells you whether the account is
private before you spend deeper calls) → `get_user_posts` or `get_user_reels` →
`get_post_comments` → act on the shortcode. For DMs: `get_inbox` →
`get_dm_messages` → `send_message`.

To publish, pass an image or video **URL**; the script fetches it and drives the
web composer.

# Rules

- **Writes are serial and explicitly approved.** Confirm the resolved target (the
  echoed `username`) before trusting an action. Instagram soft-blocks aggressive
  automation and the account at risk is the user's real one, so keep read
  fan-out modest too.
- **A short follower list on a big account is the cap, not the data.** Instagram
  serves the full list only for your own account or ones you follow; for anyone
  else you get the total `count` but a truncated preview, then `has_more` flips
  false.
- `get_post_comments` returns only the comments Instagram renders by default, and
  the first page is ranked (verified accounts first) — raw sentiment sits deeper
  than this reaches. `get_comment_replies` returns one page of a comment's thread.
- `get_profile` degrades instead of failing when the session is missing: `source`
  comes back `og_meta` and the counts are rounded, with several fields null.
  Check `source` before treating its numbers as exact.
- `view_count` is always null on `get_user_posts` — use `get_user_reels` for play
  counts.
- Timestamps: `taken_at` and `created_at` are epoch **seconds**; DM timestamps are
  **microsecond** epochs. `media_type`: 1 image, 2 video, 8 carousel.
- `send_message`'s `notice` can lag the server push, so a null value does not
  guarantee delivery.
- Reads past `get_profile` on a private account work only if the logged-in
  account follows it.
