#!/usr/bin/env bash
set -euo pipefail

# Symlinks this repo's skills and commands into the directories OpenCode reads:
#   skills/<name>/     -> ~/.agents/skills/<name>
#   commands/<name>.md -> ~/.config/opencode/commands/<name>.md
# Existing symlinks are replaced. Real files or folders are left alone.

REPO="$(cd "$(dirname "$0")/.." && pwd)"
SKILLS_DEST="$HOME/.agents/skills"
COMMANDS_DEST="$HOME/.config/opencode/commands"

link() {
  local src="$1" target="$2"
  if [ -e "$target" ] && [ ! -L "$target" ]; then
    echo "skip $target: exists and is not a symlink" >&2
    return
  fi
  ln -sfn "$src" "$target"
  echo "linked $target -> $src"
}

mkdir -p "$SKILLS_DEST"
for skill_md in "$REPO"/skills/*/SKILL.md; do
  [ -e "$skill_md" ] || continue
  src="$(dirname "$skill_md")"
  link "$src" "$SKILLS_DEST/$(basename "$src")"
done

if [ -d "$REPO/commands" ]; then
  mkdir -p "$COMMANDS_DEST"
  for command_md in "$REPO"/commands/*.md; do
    [ -e "$command_md" ] || continue
    link "$command_md" "$COMMANDS_DEST/$(basename "$command_md")"
  done
fi
