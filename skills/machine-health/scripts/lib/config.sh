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
  "$HOME/.config/worktrees" "$HOME/.worktrees" "$HOME/worktrees"
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
MH_CONFIG_LOADED=0
if [ -f "$MH_CONFIG_PATH" ]; then
  # shellcheck disable=SC1090
  . "$MH_CONFIG_PATH"
  MH_CONFIG_LOADED=1
fi

# ---- Apply defaults where the user left things unset ----
[ "${#MH_SCAN_ROOTS[@]}" -gt 0 ]   || MH_SCAN_ROOTS=("${MH_SCAN_ROOTS_DEFAULT[@]}")
if [ "${#MH_WORKTREE_DIRS[@]}" -eq 0 ]; then
  MH_WORKTREE_DIRS=("${MH_WORKTREE_DIRS_DEFAULT[@]}")
  if [ -d "$HOME/.config" ]; then
    while IFS= read -r p; do
      [ -n "$p" ] && MH_WORKTREE_DIRS+=("$p")
    done <<EOF
$(find "$HOME/.config" -mindepth 2 -maxdepth 3 -type d -name worktrees -print 2>/dev/null)
EOF
  fi
fi
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

# Count of in-scope repos (explicit MH_REPOS or auto-discovered).
mh_repo_count() { mh_repos | grep -c . || true; }

# One-line discovery SUMMARY (counts + provenance). Cheap; what a run leads with by default,
# so the operator can decide whether to expand the full list before anything proceeds.
mh_config_summary() {
  local count protect_count src
  count="$(mh_repo_count)"
  protect_count="${#MH_PROTECT_REPOS[@]}"
  if [ "$MH_CONFIG_LOADED" -eq 1 ]; then
    src="config: $MH_CONFIG_PATH"
  else
    src="auto-discovery, no config file"
  fi
  echo "## Configuration"
  echo
  echo "$count directories discovered, $protect_count protected  [$src]"
}

# Full DETAIL: provenance + the discovered repo list + protection status. Shown on demand
# (MH_SHOW_REPOS=1) so an auto-discovery run can be inspected in full when asked.
mh_config_banner() {
  local repos count protect_count
  echo "## Configuration"
  echo
  if [ "$MH_CONFIG_LOADED" -eq 1 ]; then
    echo "Config source: $MH_CONFIG_PATH"
  else
    echo "Config source: none — built-in AUTO-DISCOVERY (run configure.sh --apply to pin)"
  fi

  echo
  if [ "${#MH_REPOS[@]}" -gt 0 ]; then
    echo "Repos: explicit MH_REPOS list"
  else
    echo "Repos: auto-discovered under: $(printf '%s ' "${MH_SCAN_ROOTS[@]}")"
  fi
  repos="$(mh_repos)"
  count="$(printf '%s\n' "$repos" | grep -c . || true)"
  echo "Discovered/in-scope repos ($count):"
  if [ "$count" -eq 0 ]; then
    echo "  (none found — check MH_SCAN_ROOTS or set MH_REPOS in the config)"
  else
    printf '%s\n' "$repos" | while IFS= read -r r; do
      [ -n "$r" ] || continue
      if mh_is_protected "$r"; then
        printf '  - %s  [PROTECTED]\n' "$r"
      else
        printf '  - %s\n' "$r"
      fi
    done
  fi

  echo
  protect_count="${#MH_PROTECT_REPOS[@]}"
  if [ "$protect_count" -eq 0 ]; then
    echo "Protected repos: NONE — nothing is protected from cleanup."
    echo "  Every in-scope repo above is eligible. Set MH_PROTECT_REPOS in the config to shield one."
  else
    echo "Protected repos ($protect_count) — skipped by cleanup, tagged [PROTECTED] in the audit:"
    printf '%s\n' ${MH_PROTECT_REPOS[@]+"${MH_PROTECT_REPOS[@]}"} | sed 's/^/  - /'
  fi
}

# Dispatcher every workflow script calls: one-line summary by default, full list when asked.
mh_config_report() {
  if [ "${MH_SHOW_REPOS:-0}" = "1" ]; then
    mh_config_banner
  else
    mh_config_summary
    echo "  (run with MH_SHOW_REPOS=1 to list every discovered/protected repo)"
  fi
}
