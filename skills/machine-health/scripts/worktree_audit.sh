#!/usr/bin/env bash
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
# shellcheck source=lib/config.sh
. "$SCRIPT_DIR/lib/config.sh"

printf '# Worktree Audit\n'
date
printf '\n'
mh_config_report
printf '\n'

audit_worktrees_of() {
  local repo="$1"
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
    local tag=""
    mh_is_protected "$path" && tag=" [PROTECTED]"
    status="$(git -C "$path" status --short 2>/dev/null || true)"
    size="$(du -sh "$path" 2>/dev/null | awk '{print $1}')"
    if [ -n "$status" ]; then
      printf 'DIRTY\t%s\t%s\t%s\t%s%s\n' "${size:-?}" "$path" "$branch" "$head" "$tag"
      printf '%s\n' "$status" | sed 's/^/  /'
    else
      printf 'CLEAN\t%s\t%s\t%s\t%s%s\n' "${size:-?}" "$path" "$branch" "$head" "$tag"
    fi
  done
}

# Main checkouts (explicit MH_REPOS, else auto-discovered under scan roots).
mh_repos | while read -r repo; do
  [ -d "$repo/.git" ] || [ -f "$repo/.git" ] || continue
  printf '## %s\n\n' "$repo"
  audit_worktrees_of "$repo"
  printf '\n'
done

# Standalone worktrees living under the worktree containers.
mh_existing ${MH_WORKTREE_DIRS[@]+"${MH_WORKTREE_DIRS[@]}"} | while read -r wtdir; do
  printf '## Standalone Folders Under %s\n\n' "$wtdir"
  find "$wtdir" -mindepth 2 -maxdepth 2 -type d 2>/dev/null | while read -r path; do
    [ -d "$path/.git" ] || [ -f "$path/.git" ] || continue
    tag=""; mh_is_protected "$path" && tag=" [PROTECTED]"
    size="$(du -sh "$path" 2>/dev/null | awk '{print $1}')"
    status="$(git -C "$path" status --short 2>/dev/null || true)"
    branch="$(git -C "$path" status -sb 2>/dev/null | head -1)"
    if [ -n "$status" ]; then
      printf 'DIRTY\t%s\t%s\t%s%s\n' "${size:-?}" "$path" "$branch" "$tag"
    else
      printf 'CLEAN\t%s\t%s\t%s%s\n' "${size:-?}" "$path" "$branch" "$tag"
    fi
  done
  printf '\n'
done
