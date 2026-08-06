# reduck-skills

Agent skills that drive the [Reduck](https://reduck.ai) MCP — a catalogue of saved browser
automations, addressed as `reduck/<host>/<slug>` and run on a browser you paired through the
Reduck extension.

A skill here is a playbook, not an automation: it names the scripts worth chaining for a job and
the order to chain them in. The scripts' own contracts stay in the catalogue, read live with
`read_script`, so a skill never goes stale on argument names.

## Skills

| Skill | What it does |
| --- | --- |
| [`amazon-research`](skills/amazon-research) | Amazon US product research — search and price, listing plus review analysis, and category scans for high-demand / poorly-rated openings. |
| [`facebook-leads`](skills/facebook-leads) | Prospect and qualify leads from Facebook Group and Page activity — live communities, top threads, commenters and members. |
| [`geo-brave`](skills/geo-brave) | Why an LLM never cites your site, and which lever fixes it — harvests the queries Claude actually searches, then reads Brave's index to separate unreadable from unindexed from merely outranked. |
| [`instagram`](skills/instagram) | Read and act on Instagram — search, profiles, posts, reels, comments, follower lists, DMs, and publishing on approval. |
| [`linkedin-leads`](skills/linkedin-leads) | Prospect, qualify and act on LinkedIn leads — seed from posts or criteria, enrich the shortlist, find warm introductions, reach out on approval. |
| [`reddit`](skills/reddit) | Read, search and act on Reddit — trending, threads, topic search, pain-point mining, and posting or commenting on approval. |

More are being migrated to this layout; they land as sibling directories under `skills/`.

## Prerequisites

1. Install the Reduck browser extension and pair a browser — [start.reduck.ai](https://start.reduck.ai/).
2. Connect the Reduck MCP to your agent.

Scripts run on your paired browser, so a script marked `loggedIn` acts as whatever account is
signed in there. There is nothing else to configure.

## Install

Any agent, via the [skills CLI](https://skills.sh):

```bash
npx skills add reduck-ai/skills --list          # see what's here
npx skills add reduck-ai/skills --skill geo-brave
npx skills add reduck-ai/skills --skill '*'     # everything
npx skills use reduck-ai/skills@geo-brave       # try one without installing
```

Claude Code, via the [plugin marketplace](https://code.claude.com/docs/en/plugin-marketplaces):

```
/plugin marketplace add reduck-ai/skills
/plugin install geo-brave@reduck-skills
```

`/plugin marketplace update` pulls later changes.

For an agent that takes neither, `scripts/build-skill-zips.sh` writes one uploadable zip per
skill into `dist/` (e.g. for Claude Desktop's Settings → Capabilities → Skills → Upload).

Manual install: copy a skill's directory into your agent's skills directory, e.g.
`~/.claude/skills/geo-brave/`.

## Adding a skill

One directory per skill, one level deep: `skills/<name>/SKILL.md`, where `<name>` is
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

# <the method>

Why the flow is the way it is, then the flow.
```

Two rules keep these from rotting:

- **Addresses only in `# Requirements`.** No argument lists, no output fields — `read_script`
  answers those live, and a copy in prose is a copy that drifts. Verify every address exists
  (`list_scripts handle:"official" host:"<host>"`) before you commit it.
- **Keep what changes behavior.** A gotcha earns its place if it changes what the agent does:
  an approval gate before a write, a run-them-one-at-a-time constraint, a key that must be
  resolved rather than guessed.

Then add the skill to `.claude-plugin/marketplace.json` (one entry, `"skills": ["./skills/<name>"]`)
and to the table above.

## License

MIT. See `LICENSE`.
