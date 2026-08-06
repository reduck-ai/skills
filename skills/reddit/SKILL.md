---
name: reddit
description: |
    Read, search, and act on Reddit. Use for what's trending, a subreddit's
    threads, its rules or mods, a full thread with comments, a user's history,
    topic search across Reddit or inside one community, mining a community for
    pain points — or, on explicit approval, acting: post, crosspost, comment,
    reply, edit or delete your own content, vote, save, join, follow, DM.
    NOT for link or image posts (text posts only) or moderation actions.
---

# Requirements

- **Reduck MCP, with the browser extension installed.** If it isn't set up, follow the instructions at [start.reduck.ai](https://start.reduck.ai/).

**Discover and read**

- **`reduck/reddit.com/get_trending`**
- **`reduck/reddit.com/search_reddit`**
- **`reduck/reddit.com/search_subreddit`**
- **`reduck/reddit.com/get_subreddit_threads`**
- **`reduck/reddit.com/get_subreddit_info`**
- **`reduck/reddit.com/get_thread`**
- **`reduck/reddit.com/get_user`**
- **`reduck/reddit.com/get_inbox`**
- **`reduck/reddit.com/whoami`**

**Publish** — WRITE

- **`reduck/reddit.com/submit_post`**
- **`reduck/reddit.com/crosspost`**
- **`reduck/reddit.com/post_comment`**
- **`reduck/reddit.com/reply_comment`**

**Own content** — WRITE

- **`reduck/reddit.com/edit_post`**
- **`reduck/reddit.com/edit_comment`**
- **`reduck/reddit.com/delete_post`**
- **`reduck/reddit.com/delete_comment`**

**Engage** — WRITE

- **`reduck/reddit.com/vote`**
- **`reduck/reddit.com/save_post`**
- **`reduck/reddit.com/unsave_post`**
- **`reduck/reddit.com/join_subreddit`**
- **`reduck/reddit.com/leave_subreddit`**
- **`reduck/reddit.com/follow_user`**
- **`reduck/reddit.com/unfollow_user`**
- **`reduck/reddit.com/send_dm`**

Read their contracts live with `read_script` Reduck MCP.

The discovery reads work logged out; everything else runs as the Reddit account
signed into your paired browser — `whoami` says which one that is.

# The flow

Chain by key: `search_reddit` finds which communities discuss the topic →
`search_subreddit` or `get_subreddit_threads` finds the threads → `get_thread`
reads the conversation → `get_user` qualifies an author → engage on an approved
shortlist.

**Mining a community for pain points** has no single brick — compose it:
`search_subreddit` (or `search_reddit` with a `subreddit:name` term) over the
topic, `get_thread` on the hits that look like real complaints, then summarize
what recurs across them. Judge the thread on its title and OP text, and read the
comments for the texture.

# Rules

- **Read the target sub's rules with `get_subreddit_info` before any write.**
  Flair requirements and repost bans are the two loud failure modes.
- **`r/test` allows posts and crossposts with no flair** — rehearse a write flow
  there before touching a real community.
- **Run scripts strictly one at a time, reads included.** The paired browser
  drives a single session; parallel runs time out and can wedge it.
- **Space writes out.** Bursts of chained actions trigger `Too many requests`;
  back off a few minutes when it fires.
- `search_subreddit` returns `preview_text: null` on every sort — Reddit's
  subreddit-scoped search cards show titles only. For results *with* body
  excerpts, use `search_reddit` with a `subreddit:name` term in the query
  instead. Reddit also caps search at ~100 results per page.
- `get_thread` truncates by default: compare `num_comments` against
  `total_comments` to detect it, and pass `all_comments` to expand every "more
  replies" (slow on big threads).
- You cannot downvote or clear your vote on your **own** post — Reddit forces the
  author's upvote and reverts the change.
- `send_dm` requires a `subject` that Reddit never shows in the conversation, and
  fails for recipients who don't accept DMs.
- Deletes are irreversible, and a deleted comment leaves its replies orphaned
  under `[deleted]`.
