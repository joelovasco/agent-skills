#!/usr/bin/env bash
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
# shellcheck source=lib/config.sh
. "$SCRIPT_DIR/lib/config.sh"

section() { printf '\n## %s\n\n' "$1"; }

run() {
  printf '$ %s\n' "$*"
  "$@" 2>&1 || true
  printf '\n'
}

top_du() {
  local path="$1" depth="${2:-1}" count="${3:-25}"
  if [ -e "$path" ]; then
    du -hd "$depth" "$path" 2>&1 | sort -h | tail -"$count"
  else
    printf 'missing: %s\n' "$path"
  fi
}

printf '# Machine Health Report\n'
date
printf '\n'
mh_config_report

section "Disk"
run df -h "$HOME"

section "Memory"
run memory_pressure
run vm_stat

section "Top RAM Processes"
ps aux 2>/dev/null | sort -nrk 4 | head -20 || true

section "Local Time Machine Snapshots"
run tmutil listlocalsnapshots /

section "Core User Storage"
# worktree containers + configured storage dirs (existing only)
mh_existing ${MH_WORKTREE_DIRS[@]+"${MH_WORKTREE_DIRS[@]}"} \
            ${MH_STORAGE[@]+"${MH_STORAGE[@]}"} | while read -r path; do
  du -sh "$path" 2>&1 || true
done

section "Largest Downloads Directories"
top_du "$HOME/Downloads" 1 40

section "Largest Downloads Files"
if [ -d "$HOME/Downloads" ]; then
  find "$HOME/Downloads" -maxdepth 1 -type f -exec du -sh {} + 2>/dev/null | sort -h | tail -60
fi

section "Largest Application Support Directories"
top_du "$HOME/Library/Application Support" 1 40

section "Largest Cache Directories"
top_du "$HOME/Library/Caches" 1 40

section "Generated Repo Artifacts"
mh_search_roots | while read -r root; do
  find "$root" -maxdepth 3 \
    \( -name node_modules -o -name .next -o -name build -o -name dist -o -name coverage -o -name .tmp \) \
    -type d -print 2>/dev/null || true
done

section "Docker"
run docker ps
if [ -e "$HOME/Library/Containers/com.docker.docker/Data/vms/0/data/Docker.raw" ]; then
  ls -lh "$HOME/Library/Containers/com.docker.docker/Data/vms/0/data/Docker.raw" 2>&1 || true
  du -sh "$HOME/Library/Containers/com.docker.docker" 2>&1 || true
fi

section "Notes"
cat <<'NOTES'
- This report is read-only.
- Run clean_safe.sh --dry-run before any cleanup.
- Docker.raw, VM bundles, browser profiles, dirty worktrees, and personal Downloads files require explicit approval.
NOTES
