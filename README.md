# reduck-skills

Catalogue of Skills to teach your Agent to automate complex tasks on a browser, from optimizing your product visibility when asking Claude to finding leads on LinkedIn.

Skills use [Reduck](https://reduck.ai) MCP which allows agents to discover, run and create browser automation scripts that serve as tools. Scripts run in your own Chrome, through our extension, which allows your agent to work where you are logged in — no credentials exposure, and same fingerprints so no bot detection. 

## Skills

| Skill | What it does |
| --- | --- |
| [`geo-brave`](skills/geo-brave) | Why an LLM never cites your site, and which lever fixes it — harvests the queries Claude actually searches, then reads Brave's index to separate unreadable from unindexed from merely outranked. |
| [`saas-invoices`](skills/saas-invoices) | Fetch and download invoices for paid SaaS — list them per vendor, then route the PDF download on the invoice URL's domain. |
| [`amazon-research`](skills/amazon-research) | Amazon US product research — search and price, listing plus review analysis, and category scans for high-demand / poorly-rated openings. |
| [`facebook-leads`](skills/facebook-leads) | Prospect and qualify leads from Facebook Group and Page activity — live communities, top threads, commenters and members. |
| [`instagram`](skills/instagram) | Read and act on Instagram — search, profiles, posts, reels, comments, follower lists, DMs, and publishing on approval. |
| [`linkedin-leads`](skills/linkedin-leads) | Prospect, qualify and act on LinkedIn leads — seed from posts or criteria, enrich the shortlist, find warm introductions, reach out on approval. |
| [`reddit`](skills/reddit) | Read, search and act on Reddit — trending, threads, topic search, pain-point mining, and posting or commenting on approval. |
| [`twitter`](skills/twitter) | Read, search and act on Twitter/X — profiles, search, conversations, reposters, DMs, analytics, and posting on approval. |

## Prerequisites

Follow the instructions at [start.reduck.ai](https://start.reduck.ai/) to pair your extension and connect Reduck MCP to your agent.

## Install

### Claude marketplace

This is the preferred method if you use Claude as skills auto update:

```
/plugin marketplace add reduck-ai/skills
/plugin install geo-brave@reduck-skills
```

`/plugin marketplace update` pulls later changes.

### Skills CLI

Any agent, via the [skills CLI](https://skills.sh):

```bash
npx skills add reduck-ai/skills --list          # see what's here
npx skills add reduck-ai/skills --skill geo-brave
npx skills add reduck-ai/skills --skill '*'     # everything
npx skills use reduck-ai/skills@geo-brave       # try one without installing
```

## Contributing a skill

### Identifying / building the script

The main unit is a script which is called like a tool through Reduck MCP.

You can reference one of the [official scripts](https://reduck.ai/explore) or create your own with Reduck MCP.

### Writing skill

Skills encapsulate scripts and provide the business logic to achieve a specific goal.

Skills are available as `skills/<name>/SKILL.md`, where `<name>` is
lowercase-hyphenated and matches the `name` in the frontmatter. Nothing nests — a flat catalogue
is what makes the CLI find every skill without `--full-depth`.

The shape:

```markdown
---
name: <matches the directory>
description: |
    What it does and when to use it, in the words someone would ask for it.
    Close with a NOT-for clause — the neighbouring job it should not be used for.
---

# Requirements

- **Reduck MCP, with the browser extension installed.** If it isn't set up, follow the instructions at [start.reduck.ai](https://start.reduck.ai/).

- **`reduck/<host>/<slug>`**
- **`reduck/<host>/<slug>`**

Read their contracts live with `read_script` Reduck MCP.

```

Then add the skill to `.claude-plugin/marketplace.json` (one entry, `"skills": ["./skills/<name>"]`)
and to the table above.

## License

MIT. See `LICENSE`.
