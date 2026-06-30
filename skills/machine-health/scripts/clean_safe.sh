#!/usr/bin/env bash
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
# shellcheck source=lib/config.sh
. "$SCRIPT_DIR/lib/config.sh"

MODE=""
INCLUDE_NODE_MODULES=0

usage() {
  cat <<'USAGE'
Usage: clean_safe.sh --dry-run|--apply [--include-node-modules]

Deletes only rebuildable/generated data. Always run --dry-run first.

Default cleanup:
  - package/tool caches (universal baseline + MH_EXTRA_CACHES)
  - generated build output: .next, build, dist, coverage, .tmp (skips dirty repos)
  - prunable Git worktree metadata

Optional:
  --include-node-modules  delete node_modules only inside clean worktrees

Targets come from ~/.config/machine-health/config.sh (see configure.sh). Repos listed in
MH_PROTECT_REPOS are skipped. Never deletes Downloads, Docker.raw, VM bundles, browser
profiles, dirty worktrees, or app-support state.
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --dry-run|--apply) MODE="$1" ;;
    --include-node-modules) INCLUDE_NODE_MODULES=1 ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'Unknown argument: %s\n\n' "$1" >&2; usage; exit 2 ;;
  esac
  shift
done
[ -n "$MODE" ] || { usage >&2; exit 2; }

action() {
  local path="$1"
  [ -e "$path" ] || return 0
  if [ "$MODE" = "--dry-run" ]; then
    printf 'WOULD_DELETE\t%s\n' "$path"
  else
    printf 'DELETE\t%s\n' "$path"
    rm -rf "$path"
  fi
}

repo_root_for() {
  git -C "$(dirname "$1")" rev-parse --show-toplevel 2>/dev/null || true
}

action_generated() {
  local path="$1" root
  root="$(repo_root_for "$path")"
  if [ -n "$root" ] && mh_is_protected "$root"; then
    printf 'SKIP_PROTECTED\t%s\n' "$path"; return 0
  fi
  if [ -n "$root" ] && [ -n "$(git -C "$root" status --short 2>/dev/null || true)" ]; then
    printf 'SKIP_DIRTY_REPO\t%s\n' "$path"; return 0
  fi
  action "$path"
}

prune_worktrees() {
  local repo="$1"
  [ -d "$repo/.git" ] || [ -f "$repo/.git" ] || return 0
  if mh_is_protected "$repo"; then printf 'SKIP_PROTECTED\t%s\n' "$repo"; return 0; fi
  if [ "$MODE" = "--dry-run" ]; then
    git -C "$repo" worktree prune --dry-run --verbose 2>&1 || true
  else
    git -C "$repo" worktree prune --verbose 2>&1 || true
  fi
}

printf '# Machine Safe Cleanup (%s)\n' "$MODE"
date
printf '\n'

printf '## Package and Tool Caches\n\n'
for path in ${MH_CACHES[@]+"${MH_CACHES[@]}"}; do
  action "$path"
done

printf '\n## Generated Build Output\n\n'
mh_search_roots | while read -r root; do
  find "$root" -maxdepth 3 \
    \( -name .next -o -name build -o -name dist -o -name coverage -o -name .tmp \) \
    -type d -print 2>/dev/null
done | while read -r path; do
  action_generated "$path"
done

printf '\n## Optional node_modules\n\n'
if [ "$INCLUDE_NODE_MODULES" -eq 1 ]; then
  mh_existing ${MH_WORKTREE_DIRS[@]+"${MH_WORKTREE_DIRS[@]}"} | while read -r wtdir; do
    find "$wtdir" -maxdepth 4 -name node_modules -type d -print 2>/dev/null | while read -r path; do
      repo="$(dirname "$path")"
      if mh_is_protected "$repo"; then printf 'SKIP_PROTECTED\t%s\n' "$path"; continue; fi
      if [ -d "$repo/.git" ] || [ -f "$repo/.git" ]; then
        if [ -n "$(git -C "$repo" status --short 2>/dev/null || true)" ]; then
          printf 'SKIP_DIRTY_WORKTREE\t%s\n' "$path"; continue
        fi
      fi
      action "$path"
    done
  done
else
  printf 'SKIP\tpass --include-node-modules to remove node_modules from clean worktrees\n'
fi

printf '\n## Git Worktree Metadata Prune\n\n'
mh_repos | while read -r repo; do
  prune_worktrees "$repo"
done

printf '\n## Verification Hints\n\n'
printf 'Run: df -h "$HOME"\n'
printf 'Run: tmutil listlocalsnapshots /\n'
printf 'Run: memory_pressure\n'
