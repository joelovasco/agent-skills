#!/usr/bin/env bash
set -u

HOME_DIR="${HOME:-/Users/jlovasco}"

repos=(
  "$HOME_DIR/Documents/researcher.shared.search-ui"
  "$HOME_DIR/Documents/researcher.shared.researcher-edge-aggregator"
  "$HOME_DIR/Documents/researcher.shared.search2-edge"
  "$HOME_DIR/Documents/discover.shared.personalization-synthetics"
  "$HOME_DIR/Documents/platform.libraries.synthetics"
)

printf '# Worktree Audit\n'
date
printf '\n'

for repo in "${repos[@]}"; do
  [ -d "$repo/.git" ] || [ -f "$repo/.git" ] || continue
  printf '## %s\n\n' "$repo"
  git -C "$repo" worktree prune --dry-run --verbose 2>&1 || true
  git -C "$repo" worktree list --porcelain 2>/dev/null | awk '
    /^worktree / { if (path) print path "|" branch "|" head; path=$2; branch=""; head="" }
    /^branch / { branch=$2 }
    /^HEAD / { head=$2 }
    END { if (path) print path "|" branch "|" head }
  ' | while IFS='|' read -r path branch head; do
    [ -n "$path" ] || continue
    if [ ! -d "$path" ]; then
      printf 'MISSING\t%s\t%s\t%s\n' "$path" "$branch" "$head"
      continue
    fi
    status="$(git -C "$path" status --short 2>/dev/null || true)"
    size="$(du -sh "$path" 2>/dev/null | awk '{print $1}')"
    if [ -n "$status" ]; then
      printf 'DIRTY\t%s\t%s\t%s\t%s\n' "${size:-?}" "$path" "$branch" "$head"
      printf '%s\n' "$status" | sed 's/^/  /'
    else
      printf 'CLEAN\t%s\t%s\t%s\t%s\n' "${size:-?}" "$path" "$branch" "$head"
    fi
  done
  printf '\n'
done

printf '## Standalone Folders Under ~/.config/superpowers/worktrees\n\n'
find "$HOME_DIR/.config/superpowers/worktrees" -mindepth 2 -maxdepth 2 -type d 2>/dev/null | while read -r path; do
  [ -d "$path/.git" ] || [ -f "$path/.git" ] || continue
  size="$(du -sh "$path" 2>/dev/null | awk '{print $1}')"
  status="$(git -C "$path" status --short 2>/dev/null || true)"
  branch="$(git -C "$path" status -sb 2>/dev/null | head -1)"
  if [ -n "$status" ]; then
    printf 'DIRTY\t%s\t%s\t%s\n' "${size:-?}" "$path" "$branch"
  else
    printf 'CLEAN\t%s\t%s\t%s\n' "${size:-?}" "$path" "$branch"
  fi
done
