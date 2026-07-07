#!/usr/bin/env bash
# Builds one self-contained zip per skill for direct download (non-CLI agents,
# e.g. Claude Desktop's Settings → Capabilities → Skills → Upload).
#
# Each zip has the skill name as its single top-level folder, with SKILL.md
# directly inside it (not nested one level deeper) — that's the shape Claude
# Desktop's uploader expects.
set -euo pipefail

cd "$(dirname "$0")/.."

OUT_DIR="dist"
rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"

# Only plugins that map to exactly one skill directory — this excludes the
# convenience bundles (use-case-skills, required) which reference multiple
# skills or the repo root and aren't valid single-skill uploads.
jq -c '.plugins[] | select(.skills | length == 1) | select(.skills[0] | startswith("./skills/"))' .claude-plugin/marketplace.json |
while read -r plugin; do
  name=$(echo "$plugin" | jq -r '.name')
  skill_dir=$(echo "$plugin" | jq -r '.skills[0]' | sed 's|^\./||')

  work_dir=$(mktemp -d)
  cp -R "$skill_dir" "$work_dir/$name"

  (cd "$work_dir" && zip -r -X -q "$OLDPWD/$OUT_DIR/$name.zip" "$name")
  rm -rf "$work_dir"

  echo "built $OUT_DIR/$name.zip (from $skill_dir)"
done
