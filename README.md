# Reduck Agents

This is a repository of reference agents, which package skills and [Reduck](https://reduck.ai) MCP, to perform complex tasks, from optimizing your GEO with Reduck GEO to doing your invoices with Reduck Invoices.

Reduck MCP allows agents to discover, run and create browser automation scripts that serve as tools. Scripts run in your own Chrome, through our extension, which allows your agent to work where you are logged in — no credentials exposure, and same fingerprints so no bot detection.

## Agents

| Agent | What it does |
| --- | --- |
| [`reduck-geo`](skills/reduck-geo) | Get your site cited by Claude — see which queries it searches, check how you show up in Brave (the index behind its web search), and fix what's holding you back. |
| [`reduck-invoices`](skills/reduck-invoices) | Fetch and download invoices for paid SaaS — list them per vendor, then route the PDF download on the invoice URL's domain. |

## Prerequisites

Follow the instructions at [start.reduck.ai](https://start.reduck.ai/) to pair your extension and connect Reduck MCP to your agent.

## Install

### Claude marketplace

This is the preferred method if you use Claude as agents auto update:

```
/plugin marketplace add reduck-ai/agents
/plugin install reduck-geo@reduck-agents
```

`/plugin marketplace update` pulls later changes.

### Skills CLI

Any agent, via the [skills CLI](https://skills.sh):

```bash
npx skills add reduck-ai/agents --list          # see what's here
npx skills add reduck-ai/agents --skill reduck-geo
npx skills add reduck-ai/agents --skill '*'     # everything
npx skills use reduck-ai/agents@reduck-geo      # try one without installing
```

## Contributing an agent

### Identifying / building the script

The main unit is a script which is called like a tool through Reduck MCP.

You can reference one of the [official scripts](https://reduck.ai/explore) or create your own with Reduck MCP.

### Writing the agent

An agent encapsulates scripts and provides the business logic to achieve a specific goal.

Each one lives at `skills/reduck-<name>/SKILL.md`, where the directory matches the `name` in the
frontmatter. The directory and filename are fixed by the [Agent Skills spec](https://agentskills.io)
— that is what lets both installers find it — so `Reduck X` is the name, `reduck-x` the id.
Nothing nests: a flat catalogue is what makes the CLI find every agent without `--full-depth`.

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

List the script addresses and nothing more — `read_script` returns the arguments and outputs
live, so a copy here is a copy that drifts. Verify each address exists
(`list_scripts handle:"official" host:"<host>"`) before committing it.

Then add the agent to `.claude-plugin/marketplace.json` (one entry,
`"skills": ["./skills/reduck-<name>"]`) and to the table above.

## License

MIT. See `LICENSE`.
