# reduck-skill

Agent Skill that teaches any compatible coding agent (Claude Code, Codex, Cursor, OpenCode, …) to drive the [Reduck](https://reduck.dev) CLI as a function: discover a method, call it, read the records back.

Reduck runs web automations from the terminal — scraping, structured extraction, logging into sites and pulling messages, SPA-aware fetches, paginated Google site-search. The default LLM failure mode is to chat with it instead of treating it as a function call. This skill corrects for that.

## Install

Via the [skills CLI](https://skills.sh):

```bash
npx skills add conception-ai/reduck-skill
```

Manual install — copy or clone `SKILL.md` into your agent's skills directory, e.g. `~/.claude/skills/reduck/SKILL.md`.

## Prerequisites

```bash
npm install -g @reduck-ai/cli
reduck login        # OAuth PKCE, opens a browser
reduck devices      # pick the device the CLI will dispatch to
```

Optional: set `REDUCK_DEVICE_ID=<chrome-profile>` to allow concurrent agent sessions on the same machine.

## License

MIT. See `LICENSE`.
