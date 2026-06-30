#!/usr/bin/env bash
set -u

HOME_DIR="${HOME:-/Users/jlovasco}"
MODE=""
INCLUDE_NODE_MODULES=0

usage() {
  cat <<'USAGE'
Usage: clean_safe.sh --dry-run|--apply [--include-node-modules]

Deletes only rebuildable/generated data. Always run --dry-run first.

Default cleanup:
  - package/tool caches
  - app/developer caches known to be rebuildable
  - generated build output: .next, build, dist, coverage, .tmp
  - prunable Git worktree metadata

Optional:
  --include-node-modules  delete node_modules only inside clean worktrees

Never deletes Downloads, Docker.raw, Claude VM bundles, browser profiles,
dirty worktrees, or app-support state.
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

if [ -z "$MODE" ]; then
  usage >&2
  exit 2
fi

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
  local path="$1"
  git -C "$(dirname "$path")" rev-parse --show-toplevel 2>/dev/null || true
}

action_generated() {
  local path="$1"
  local root
  root="$(repo_root_for "$path")"
  if [ -n "$root" ] && [ -n "$(git -C "$root" status --short 2>/dev/null || true)" ]; then
    printf 'SKIP_DIRTY_REPO\t%s\n' "$path"
    return 0
  fi
  action "$path"
}

prune_worktrees() {
  local repo="$1"
  [ -d "$repo/.git" ] || [ -f "$repo/.git" ] || return 0
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
for path in \
  "$HOME_DIR/.npm/_cacache" \
  "$HOME_DIR/.npm/_npx" \
  "$HOME_DIR/.npm/_logs" \
  "$HOME_DIR/Library/Caches/Cypress" \
  "$HOME_DIR/Library/Caches/Yarn" \
  "$HOME_DIR/Library/Caches/ms-playwright" \
  "$HOME_DIR/Library/Caches/ms-playwright-mcp" \
  "$HOME_DIR/.cache/puppeteer" \
  "$HOME_DIR/.cache/uv" \
  "$HOME_DIR/Library/Caches/JetBrains" \
  "$HOME_DIR/Library/Caches/com.spotify.client" \
  "$HOME_DIR/Library/Caches/com.microsoft.VSCode.ShipIt" \
  "$HOME_DIR/Library/Caches/com.postmanlabs.mac.ShipIt" \
  "$HOME_DIR/Library/Caches/node-gyp" \
  "$HOME_DIR/Library/Caches/typescript" \
  "$HOME_DIR/Library/Caches/puccinialin" \
  "$HOME_DIR/Library/Caches/pip" \
  "$HOME_DIR/Library/Caches/Homebrew"; do
  action "$path"
done

printf '\n## Generated Build Output\n\n'
find "$HOME_DIR/.config/superpowers/worktrees" "$HOME_DIR/Documents" \
  -maxdepth 3 \
  \( -name .next -o -name build -o -name dist -o -name coverage -o -name .tmp \) \
  -type d -print 2>/dev/null | while read -r path; do
  action_generated "$path"
done

printf '\n## Optional node_modules\n\n'
if [ "$INCLUDE_NODE_MODULES" -eq 1 ]; then
  find "$HOME_DIR/.config/superpowers/worktrees" \
    -maxdepth 4 -name node_modules -type d -print 2>/dev/null | while read -r path; do
    repo="$(dirname "$path")"
    if [ -d "$repo/.git" ] || [ -f "$repo/.git" ]; then
      if [ -n "$(git -C "$repo" status --short 2>/dev/null || true)" ]; then
        printf 'SKIP_DIRTY_WORKTREE\t%s\n' "$path"
        continue
      fi
    fi
    action "$path"
  done
else
  printf 'SKIP\tpass --include-node-modules to remove node_modules from clean worktrees\n'
fi

printf '\n## Git Worktree Metadata Prune\n\n'
for repo in \
  "$HOME_DIR/Documents/researcher.shared.search-ui" \
  "$HOME_DIR/Documents/researcher.shared.researcher-edge-aggregator" \
  "$HOME_DIR/Documents/researcher.shared.search2-edge" \
  "$HOME_DIR/Documents/discover.shared.personalization-synthetics" \
  "$HOME_DIR/Documents/platform.libraries.synthetics"; do
  prune_worktrees "$repo"
done

printf '\n## Verification Hints\n\n'
printf 'Run: df -h "$HOME"\n'
printf 'Run: tmutil listlocalsnapshots /\n'
printf 'Run: memory_pressure\n'
