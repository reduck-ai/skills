# reduck-skills

Agent Skill that teaches any compatible coding agent (Claude Code, Codex, Cursor, OpenCode, …) to drive the [Reduck](https://reduck.dev) CLI as a function: discover a method, call it, read the records back.

Reduck runs web automations from the terminal — scraping, structured extraction, logging into sites and pulling messages, SPA-aware fetches, paginated Google site-search. The default LLM failure mode is to chat with it instead of treating it as a function call. This skill corrects for that.

## Skills in this repo

This repo is a small catalogue. The generalist `reduck` skill is the base; the
lead-gen verticals build on it.

```
skills/
├── reduck/                       # generalist — REQUIRED base for the verticals
└── lead-gen/
    ├── linkedin/leads/           # linkedin-leads
    └── facebook/leads/           # facebook-leads
```

There is no `SKILL.md` at the repo root, so the [skills CLI](https://skills.sh)
discovers every skill recursively.

## Install

### Any agent — via the skills CLI

```bash
# Interactive picker — choose what to install (a human terminal shows checkboxes)
npx skills add reduck-ai/skills

# Just list what's available, install nothing
npx skills add reduck-ai/skills --list

# Install a specific skill. The verticals need the reduck base, so install both
# (repeat the --skill flag — a comma-separated list is NOT parsed as multiple):
npx skills add reduck-ai/skills --skill reduck --skill facebook-leads
npx skills add reduck-ai/skills --skill reduck --skill linkedin-leads

# Try a skill's prompt without installing it
npx skills use reduck-ai/skills@facebook-leads
```

Note: inside a coding agent (or with `-y`) the CLI is non-interactive and installs
**all** discovered skills. The checkbox picker only appears in a human TTY without
flags. The `reduck` skill is the REQUIRED base — the verticals assume it is present
for the bridge lifecycle and how to run a script.

Manual install — copy or clone the skill's `SKILL.md` into your agent's skills
directory, e.g. `~/.claude/skills/facebook-leads/SKILL.md`.

### Claude Code — via the plugin marketplace

This repo is also a Claude Code [plugin marketplace](https://code.claude.com/docs/en/plugin-marketplaces).
Inside Claude Code:

```
/plugin marketplace add reduck-ai/skills
/plugin install reduck@reduck-skills
```

`/plugin marketplace update` pulls future changes. The `reduck` plugin bundles all
three skills.

## Prerequisites

```bash
npx -y @reduck-ai/cli@latest login   # OAuth PKCE, opens a browser
npx -y @reduck-ai/cli@latest local   # start the local browser bridge; hand its wss:// URL to the MCP
```

The bridge is a machine-wide singleton — one `reduck local` serves any number of
concurrent consumers, each its own fresh Chrome, so no per-device selection is
needed. Target another MCP (staging, a local dev server) with `REDUCK_MCP_URL`.

## License

MIT. See `LICENSE`.
