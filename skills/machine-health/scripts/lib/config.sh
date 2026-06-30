#!/usr/bin/env bash
# Shared config loader for machine-health.
#
# Resolution order:
#   1. $MACHINE_HEALTH_CONFIG (explicit path)
#   2. ~/.config/machine-health/config.sh   (written by configure.sh)
#   3. built-in defaults below (generic auto-discovery — no machine-specific paths)
#
# Safe to source under `set -u` on bash 3.2 (stock macOS). Arrays are expanded with the
# ${arr[@]+"${arr[@]}"} guard so empty arrays never trip "unbound variable".

: "${HOME:?HOME must be set}"

MH_CONFIG_PATH="${MACHINE_HEALTH_CONFIG:-$HOME/.config/machine-health/config.sh}"

# ---- Built-in defaults (generic; only existing paths are ever acted on) ----
MH_SCAN_ROOTS_DEFAULT=(
  "$HOME/Documents" "$HOME/code" "$HOME/src" "$HOME/projects"
  "$HOME/dev" "$HOME/work" "$HOME/repos" "$HOME/git"
)
MH_WORKTREE_DIRS_DEFAULT=(
  "$HOME/.config/superpowers/worktrees"
)
# Universal, rebuildable dev/tool caches.
MH_CACHES_DEFAULT=(
  "$HOME/.npm/_cacache" "$HOME/.npm/_npx" "$HOME/.npm/_logs"
  "$HOME/Library/Caches/Cypress" "$HOME/Library/Caches/Yarn"
  "$HOME/Library/Caches/ms-playwright" "$HOME/Library/Caches/ms-playwright-mcp"
  "$HOME/.cache/puppeteer" "$HOME/.cache/uv"
  "$HOME/Library/Caches/JetBrains" "$HOME/Library/Caches/com.spotify.client"
  "$HOME/Library/Caches/com.microsoft.VSCode.ShipIt"
  "$HOME/Library/Caches/com.postmanlabs.mac.ShipIt"
  "$HOME/Library/Caches/node-gyp" "$HOME/Library/Caches/typescript"
  "$HOME/Library/Caches/puccinialin" "$HOME/Library/Caches/pip"
  "$HOME/Library/Caches/Homebrew"
)
MH_STORAGE_DEFAULT=(
  "$HOME/Downloads" "$HOME/.npm" "$HOME/.cache"
  "$HOME/Library/Caches" "$HOME/Library/Containers/com.docker.docker"
  "$HOME/Library/Application Support"
)

# ---- User-overridable arrays (config may set any of these) ----
MH_SCAN_ROOTS=()
MH_WORKTREE_DIRS=()
MH_REPOS=()            # explicit repos to audit/prune; empty => auto-discover under scan roots
MH_EXTRA_CACHES=()     # appended to the universal baseline
MH_PROTECT_REPOS=()    # never-clean repos (by basename or full path). EMPTY = nothing protected.

# ---- Load user config if present ----
if [ -f "$MH_CONFIG_PATH" ]; then
  # shellcheck disable=SC1090
  . "$MH_CONFIG_PATH"
fi

# ---- Apply defaults where the user left things unset ----
[ "${#MH_SCAN_ROOTS[@]}" -gt 0 ]   || MH_SCAN_ROOTS=("${MH_SCAN_ROOTS_DEFAULT[@]}")
[ "${#MH_WORKTREE_DIRS[@]}" -gt 0 ] || MH_WORKTREE_DIRS=("${MH_WORKTREE_DIRS_DEFAULT[@]}")
MH_CACHES=("${MH_CACHES_DEFAULT[@]}")
MH_CACHES+=( ${MH_EXTRA_CACHES[@]+"${MH_EXTRA_CACHES[@]}"} )
MH_STORAGE=("${MH_STORAGE_DEFAULT[@]}")

# ---- Helpers ----

# Print only the existing paths from the args, one per line.
mh_existing() {
  local p
  for p in "$@"; do [ -e "$p" ] && printf '%s\n' "$p"; done
}

# Discover main git checkouts (a dir containing a .git DIRECTORY) under the scan roots.
mh_discover_repos() {
  local root
  for root in ${MH_SCAN_ROOTS[@]+"${MH_SCAN_ROOTS[@]}"}; do
    [ -d "$root" ] || continue
    find "$root" -mindepth 1 -maxdepth 2 -type d -name .git -prune 2>/dev/null \
      | sed 's#/\.git$##'
  done | sort -u
}

# Effective repo list: explicit MH_REPOS if set, else auto-discovered.
mh_repos() {
  if [ "${#MH_REPOS[@]}" -gt 0 ]; then
    printf '%s\n' "${MH_REPOS[@]}"
  else
    mh_discover_repos
  fi
}

# Search roots for "generated artifacts" / worktrees: worktree dirs + scan roots that exist.
mh_search_roots() {
  mh_existing ${MH_WORKTREE_DIRS[@]+"${MH_WORKTREE_DIRS[@]}"} \
              ${MH_SCAN_ROOTS[@]+"${MH_SCAN_ROOTS[@]}"}
}

# Is a repo/worktree path protected from cleanup? Matches basename or full path.
mh_is_protected() {
  local path="$1" base p
  base="$(basename "$path")"
  for p in ${MH_PROTECT_REPOS[@]+"${MH_PROTECT_REPOS[@]}"}; do
    [ -n "$p" ] || continue
    [ "$p" = "$base" ] || [ "$p" = "$path" ] && return 0
  done
  return 1
}
