---
name: twitter
description: |
  Read, search, and act on Twitter/X through saved Reduck scripts, via two
  routes: public scraping through xcancel.com (Nitter — no login, no session
  risk) and authenticated actions through x.com (the user's real account).
  Use when the user wants anything from Twitter/X: a profile, a user's
  tweets/media, tweet search, a tweet's replies or reposters,
  followers/following, their own feed/mentions/DMs, post analytics — or, on
  explicit approval, acting: post a tweet/thread (with media), reply, quote,
  retweet, like, bookmark, DM, follow/mute/block. Triggers: "get <user>'s
  tweets", "search Twitter/X for X", "who retweeted this", "my
  mentions/DMs/feed", "post/reply/quote on X", "DM <user> on Twitter".
  NOT for: a tweet's likers (X made likes private in 2024) or
  followers/following via the public route (Nitter 404s them — authed x.com
  only). Needs the reduck base plugin.
license: Complete terms in LICENSE
---

# Twitter / X

Reduck scripts that turn Twitter/X flows into callable building blocks, on two
hosts. Each script is a pointer — read its contract (`read_script`,
`handle: reduck`) for exact args and output. Addresses are
`reduck/<host>/<slug>`: e.g. `run_script` with script
`reduck/x.com/get_user_info` and args `{"handle": "anthropic"}`.

**Route choice.** Prefer `xcancel.com` (Nitter mirror) for public reads:
profiles, timelines, media, tweet + replies, tweet/user search. It needs no
login, spends none of the user's session, and takes full X advanced-search
syntax. Use `x.com` when the read is inherently account-side (followers,
feed, mentions, DMs, analytics) or for any write. All `x.com` scripts are
`loggedIn` and act as whatever account is in the real Chrome cookie jar —
expose it via `reduck local --cookies` (see the `reduck` skill for the device
lifecycle) and **run local-headed**; the xcancel antibot clears headful only,
so the same rule covers both hosts.

**One at a time.** Run scripts strictly sequentially — reads included. The
local device drives a single browser session; parallel `run_script` calls
fail with 504/worker-socket timeouts and can wedge the device. X also
throttles aggressive pagination, and the account at risk is the user's real
one.

Writes are marked **WRITE** — they publish or act under the user's real
account. Run them only on explicit human approval and verify the echoed
result (`id`/`url`/`was_*`). They were validated on a test account, not a
main one — treat the first write on a real account as a live test.

## Keys and conventions

- `handle` / `username` — without the `@` (both hosts accept `@` too, but the
  bare form always works).
- `tweet_url` — full status URL, `https://x.com/<handle>/status/<id>`; the
  numeric `<id>` is the join key everywhere.
- Pagination differs by host: `x.com` scripts scroll until `count` is met or
  the list dries up; `xcancel.com` scripts return one page plus an opaque
  `cursor` (pass it back; `null` = no more pages).
- Toggle writes are idempotent: they detect current state and report
  `was_liked`/`was_retweeted`/`was_following`… instead of erroring or
  re-clicking.
- DM scripts may hit X's E2E "Enter Passcode" screen on a fresh session —
  pass the account's 4-digit `pin` arg when they do. The pin is the user's
  secret: ask for it, don't guess.

## Public scraping — `reduck/xcancel.com/<slug>`

All take an optional `host` (default `xcancel.com`) so a dead Nitter instance
is a one-arg swap — pick a live one from the community instance tracker
(status.d420.de). Cold loads sit through a JS antibot interstitial —
sometimes >10s; the scripts allow 30s, don't shorten it.

- `get_user_profile` — `(username)` → bio, location, website, join date,
  avatar/banner, tweet/following/follower/like counts.
- `get_user_tweets` — `(username, cursor?)` → timeline page (tweets +
  retweets, no replies): id, url, author, date, content, reply/retweet/
  quote/like counts, images, videos (direct twimg URLs), quote, pinned,
  retweetedBy.
- `get_user_tweets_with_replies` — same shape plus `replyingTo`.
- `get_user_media` — same shape, filtered to media tweets.
- `get_tweet` — `(username, id, cursor?)` → the tweet (stats, media, quote)
  plus its flattened reply thread.
- `search_tweets` — `(query, cursor?)` → full X operator syntax (`from:`,
  `min_faves:`, `since:`/`until:`, quoted phrases).
- `search_users` — `(query, cursor?)` → matching profiles (handle, name,
  verified, bio, avatar).
- Gotcha: `views` only populates on search and single-tweet pages — null on
  profile timelines is the source, not a bug.

## Authenticated reads — `reduck/x.com/<slug>`

- `get_user_info` — `(handle)` → profile + `user_id`, `is_following`,
  `follows_you`. On your own profile `user_id`/`is_following` are null.
- `get_user_tweets` — `(handle, count default 100)` → tweets with full
  counts incl. views and bookmarks; depth capped by X's timeline throttling.
- `search_tweets` — `(query, tab top|latest, count ≤100)` → tweets with
  author follower counts. `top` is a ranked sample; combining
  `-filter:replies` with `min_faves`+`since` can return zero (X quirk).
- `get_replies` — `(tweet_url, count)` → a tweet's replies. Ranked sample,
  not the full set.
- `get_reposters` — `(url = tweet_url, count ≤1000)` → accounts that retweeted, with full
  profile data for ranking. Sample — high-repost posts cap a few hundred deep.
- `get_followers` / `get_following` — `(handle, count ≤1000)` → accounts with
  full profile data (followers, bio, location…). The only follower-list
  route — Nitter can't.
- `get_personal_feed` — `(count ≤50)` → your For You feed. For a retweet the
  `id` is the wrapper; join via `retweeted_tweet.id`.
- `get_mentions` — `(count)` → Notifications > Mentions of the logged-in
  account. *Only validated against an empty inbox — treat the first real run
  as a live test.*
- `get_post_analytics` — `(post = status URL or bare numeric id)` →
  owner-only panel (impressions,
  engagements, profile visits, link clicks…) as label→value pairs; counts
  like `1.2K` come back approximate. Own posts only; re-run on X's transient
  Retry error.

**DMs.**

- `get_inbox` — `(pin?)` → every conversation: conversation_id, handle,
  last_message, time, sent_by_me, unread.
- `get_messages` — `(handle, pin?)` → full conversation with one user.
- `send_dm` — **WRITE** — `(handle, message, pin?)` → sent status +
  conversation_id.

## Act — `reduck/x.com/<slug>` (all WRITE)

- `post_tweet` — `(text ≤280, media_path?)` → id, url. `media_path` attaches
  an image/video by path on the machine running the local device; X's
  validator rejects tiny/synthetic images — use a real file. Fails loud if media was requested but didn't attach.
- `post_thread` — `(tweets: string[] ≤25)` → the native multi-post composer;
  returns each tweet's id/url in order plus the root url.
- `reply_to_tweet` / `quote_tweet` — `(tweet_url, text)` → new tweet id/url.
- `retweet` / `unretweet`, `like_tweet` / `unlike_tweet`, `bookmark_tweet` —
  `(tweet_url)` → idempotent toggles reporting `was_*`.
- `delete_tweet` — `(tweet_url)` → deletes your own tweet. Irreversible.
- `follow_user` / `unfollow_user`, `mute_user` / `unmute_user`,
  `block_user` / `unblock_user` — `(handle)` → idempotent; errors on
  missing/suspended accounts.

## Usage notes

- Chain by key: discover via xcancel `search_tweets`/`search_users` → deepen
  with `get_tweet`/`get_user_tweets` → pivot to x.com for the audience
  (`get_reposters`, `get_replies`, `get_followers`) → act on the shortlist
  (`follow_user`, `reply_to_tweet`, `send_dm`).
- Public posting needs explicit authorization from the user for the specific
  content and target — a general "post about X" is not approval for a
  particular tweet text.
