#!/usr/bin/env bash
# install.sh — symlink agent-skills into the tools' skill-discovery dirs.
#
# Skills are INDEPENDENT: each skills/<name> is symlinked on its own into whichever of
#   ~/.claude/skills   (Claude Code)
#   ~/.codex/skills    (Codex)
#   ~/.agents/skills   (shared convention)
# exist on this machine. `git pull` updates everything — the links point at the working tree.
#
# Usage:
#   ./install.sh [--dry-run] [--uninstall] [skill ...]
#   ./install.sh                  # all skills
#   ./install.sh machine-health   # just one
#   ./install.sh --dry-run        # preview, change nothing
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_SRC="$REPO_DIR/skills"

# A target root is used only if its parent (the tool's home) exists.
TARGET_ROOTS=(
  "${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"
  "${CODEX_SKILLS_DIR:-$HOME/.codex/skills}"
  "${AGENT_SKILLS_DIR:-$HOME/.agents/skills}"
)

DRY_RUN=0
UNINSTALL=0
NAMES=()
for arg in "$@"; do
  case "$arg" in
    --dry-run)   DRY_RUN=1 ;;
    --uninstall) UNINSTALL=1 ;;
    -h|--help)   sed -n '2,18p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*)          echo "unknown flag: $arg" >&2; exit 2 ;;
    *)           NAMES+=("$arg") ;;
  esac
done

# Default to every skill folder in the repo.
if [ "${#NAMES[@]}" -eq 0 ]; then
  for d in "$SKILLS_SRC"/*/; do
    [ -d "$d" ] || continue
    NAMES+=("$(basename "$d")")
  done
fi
if [ "${#NAMES[@]}" -eq 0 ]; then echo "No skills found in $SKILLS_SRC"; exit 0; fi

run() { if [ "$DRY_RUN" -eq 1 ]; then echo "      would: $*"; else "$@"; fi; }

for name in "${NAMES[@]}"; do
  src="$SKILLS_SRC/$name"
  if [ "$UNINSTALL" -eq 0 ] && [ ! -d "$src" ]; then
    echo "SKIP   $name (no skills/$name in repo)"; continue
  fi
  for root in "${TARGET_ROOTS[@]}"; do
    parent="$(dirname "$root")"
    [ -d "$parent" ] || continue          # tool not installed → skip its root
    link="$root/$name"

    if [ "$UNINSTALL" -eq 1 ]; then
      if [ -L "$link" ]; then echo "UNLINK $name  ($root)"; run rm "$link"; fi
      continue
    fi

    run mkdir -p "$root"
    if [ -L "$link" ]; then
      cur="$(readlink "$link")"
      if [ "$cur" = "$src" ]; then echo "OK     $name  ($root)"; continue; fi
      echo "RELINK $name  ($root): $cur -> $src"
      run rm "$link"; run ln -s "$src" "$link"
    elif [ -e "$link" ]; then
      echo "WARN   $name  ($root): exists and is NOT a symlink — left untouched."
      echo "       Remove '$link' and re-run to link it."
    else
      echo "LINK   $name  ($root) -> $src"
      run ln -s "$src" "$link"
    fi
  done
done

# Setup hints: a skill with a configure.sh wants a one-time customization pass.
if [ "$UNINSTALL" -eq 0 ]; then
  for name in "${NAMES[@]}"; do
    cfg="$SKILLS_SRC/$name/scripts/configure.sh"
    [ -f "$cfg" ] && echo "SETUP  $name: run 'skills/$name/scripts/configure.sh --print' to customize for this machine"
  done
fi

[ "$DRY_RUN" -eq 1 ] && echo "(dry-run — nothing changed)" || true
