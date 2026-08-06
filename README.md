# reduck-skills

Agent Skill that teaches any compatible coding agent (Claude Code, Codex, Cursor, OpenCode, …) to drive the [Reduck](https://reduck.dev) CLI as a function: discover a method, call it, read the records back.

Reduck runs web automations from the terminal — scraping, structured extraction, logging into sites and pulling messages, SPA-aware fetches, paginated Google site-search. The default LLM failure mode is to chat with it instead of treating it as a function call. This skill corrects for that.

## Skills in this repo

This repo is a small catalogue. The generalist `reduck` skill is the base; the
lead-gen, product-research, ops and social verticals build on it.

```
SKILL.md                          # → skills/reduck/SKILL.md (the default install)
skills/
├── reduck/                       # generalist — REQUIRED base for the verticals
├── lead-gen/
│   ├── linkedin/leads/           # linkedin-leads
│   └── facebook/leads/           # facebook-leads
├── product-research/
│   └── amazon/research/          # amazon-research
├── ops/
│   └── billing/invoices/         # saas-invoices
├── social/
│   ├── instagram/engage/         # instagram
│   ├── reddit/engage/            # reddit
│   └── twitter/engage/           # twitter
└── geo_brave/                    # geo_brave — standalone, MCP-based, no reduck base needed
```

The repo-root `SKILL.md` is the generalist `reduck` skill, so the
[skills CLI](https://skills.sh) installs **just `reduck` by default**. The
verticals are opt-in: pass `--full-depth` (or `--skill <name> --full-depth`) to
discover them, or install them individually via the Claude Code marketplace below.

## Install

### Any agent — via the skills CLI

```bash
# Default — installs just the reduck base skill
npx skills add reduck-ai/skills

# See the verticals too (they live below the root SKILL.md, so need --full-depth).
# The picker groups them: "Required" (reduck) first, then "Use Case Skills".
npx skills add reduck-ai/skills --list --full-depth

# Install a vertical. The verticals need the reduck base AND --full-depth to be
# discovered (repeat --skill — a comma-separated list is NOT parsed as multiple):
npx skills add reduck-ai/skills --full-depth --skill reduck --skill facebook-leads
npx skills add reduck-ai/skills --full-depth --skill reduck --skill linkedin-leads
npx skills add reduck-ai/skills --full-depth --skill reduck --skill saas-invoices

# geo_brave is standalone — it drives the Reduck MCP, not the CLI, so it needs no base
npx skills add reduck-ai/skills --full-depth --skill geo_brave

# Everything in one go
npx skills add reduck-ai/skills --full-depth --skill '*'

# Try a skill's prompt without installing it
npx skills use reduck-ai/skills@facebook-leads
```

Note: inside a coding agent (or with `-y`) the CLI is non-interactive. With the
root `SKILL.md` present it installs **just `reduck`** by default; add `--full-depth`
to pull the verticals. The `reduck` skill is the REQUIRED base — the verticals
assume it is present for the bridge lifecycle and how to run a script.

Manual install — copy or clone the skill's `SKILL.md` into your agent's skills
directory, e.g. `~/.claude/skills/facebook-leads/SKILL.md`.

### Claude Code — via the plugin marketplace

This repo is also a Claude Code [plugin marketplace](https://code.claude.com/docs/en/plugin-marketplaces).
Inside Claude Code:

```
/plugin marketplace add reduck-ai/skills
/plugin install reduck@reduck-skills          # the REQUIRED base, on its own
/plugin install linkedin-leads@reduck-skills  # + only the verticals you want
```

Install is granular — one plugin per skill, so you only load the descriptions you
use (an unused skill still costs context). The verticals (`linkedin-leads`,
`facebook-leads`, `amazon-research`, `saas-invoices`, `instagram`, `reddit`,
`twitter`) assume the `reduck` base is installed; there
is no auto-dependency, so install `reduck` alongside any vertical. The exception is
`geo_brave`, which drives the Reduck MCP rather than the CLI and installs on its own:

```
/plugin install geo_brave@reduck-skills       # standalone, no base required
```

Prefer one command for everything? Use the convenience bundle:

```
/plugin install required@reduck-skills         # just the reduck base
/plugin install use-case-skills@reduck-skills  # all verticals
```

`/plugin marketplace update` pulls future changes.

## Prerequisites

```bash
npx -y @reduck-ai/cli@latest login   # OAuth PKCE, opens a browser
npx -y @reduck-ai/cli@latest local   # start the bridge to your browser; hand its wss:// URL to the MCP
```

The bridge is a machine-wide singleton — one `reduck local` serves any number of
concurrent consumers, each its own fresh Chrome, so no per-device selection is
needed. Target another MCP (staging, a local dev server) with `REDUCK_MCP_URL`.

## License

MIT. See `LICENSE`.
