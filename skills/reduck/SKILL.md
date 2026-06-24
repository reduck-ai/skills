---
name: reduck
description: |
  REQUIRED base skill — install this first; every lead-gen vertical
  (facebook-leads, linkedin-leads) needs it.
  Run web tasks through Reduck: scrape a site, extract structured records,
  search LinkedIn/Reddit/Google, log in and pull messages, fetch SPA/JS-gated
  pages, paginate site-search. Use when the user says "scrape", "get data from
  <site>", "search <site> for X", "pull my latest messages on <platform>",
  "extract <field> from <URL>", or asks for any data behind a webpage rather
  than a public API. NOT for: writing browser automation from scratch, or tasks
  where a first-party API already exists.
license: Complete terms in LICENSE
---

# Reduck

This skill is a thin wrapper: the real instructions are the MCP's `read_docs`
(the conceptual model + MCP tools) and the `reduck` CLI's own `--help` (how to
drive it from a terminal), both inlined live below via bash-macros the loader
expands at load time. If a block renders as literal text, run its command yourself.

## Concepts & MCP tools

!`npx -y @reduck-ai/cli@latest skill 2>&1`

## CLI usage

The same scripts run from a terminal via the `reduck` CLI. Its commands and flags,
straight from the CLI itself (the authoritative, drift-free source):

!`npx -y @reduck-ai/cli@latest --help 2>&1`

!`npx -y @reduck-ai/cli@latest run --help 2>&1`

!`npx -y @reduck-ai/cli@latest local --help 2>&1`
