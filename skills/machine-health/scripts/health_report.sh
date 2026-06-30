#!/usr/bin/env bash
set -u

HOME_DIR="${HOME:-/Users/jlovasco}"

section() {
  printf '\n## %s\n\n' "$1"
}

run() {
  printf '$ %s\n' "$*"
  "$@" 2>&1 || true
  printf '\n'
}

top_du() {
  local path="$1"
  local depth="${2:-1}"
  local count="${3:-25}"
  if [ -e "$path" ]; then
    du -hd "$depth" "$path" 2>&1 | sort -h | tail -"$count"
  else
    printf 'missing: %s\n' "$path"
  fi
}

printf '# Machine Health Report\n'
date

section "Disk"
run df -h "$HOME_DIR"

section "Memory"
run memory_pressure
run vm_stat

section "Top RAM Processes"
ps aux 2>/dev/null | sort -nrk 4 | head -20 || true

section "Local Time Machine Snapshots"
run tmutil listlocalsnapshots /

section "Core User Storage"
for path in \
  "$HOME_DIR/Downloads" \
  "$HOME_DIR/.config/superpowers/worktrees" \
  "$HOME_DIR/.npm" \
  "$HOME_DIR/.cache" \
  "$HOME_DIR/Library/Caches" \
  "$HOME_DIR/Library/Containers/com.docker.docker" \
  "$HOME_DIR/Library/Application Support/Claude" \
  "$HOME_DIR/Library/Application Support/Google" \
  "$HOME_DIR/Library/Application Support/JetBrains"; do
  du -sh "$path" 2>&1 || true
done

section "Largest Downloads Directories"
top_du "$HOME_DIR/Downloads" 1 40

section "Largest Downloads Files"
if [ -d "$HOME_DIR/Downloads" ]; then
  find "$HOME_DIR/Downloads" -maxdepth 1 -type f -exec du -sh {} + 2>/dev/null | sort -h | tail -60
fi

section "Largest Application Support Directories"
top_du "$HOME_DIR/Library/Application Support" 1 40

section "Largest Cache Directories"
top_du "$HOME_DIR/Library/Caches" 1 40

section "Generated Repo Artifacts"
find "$HOME_DIR/.config/superpowers/worktrees" "$HOME_DIR/Documents" \
  -maxdepth 3 \
  \( -name node_modules -o -name .next -o -name build -o -name dist -o -name coverage -o -name .tmp \) \
  -type d -print 2>/dev/null || true

section "Docker"
run docker ps
if [ -e "$HOME_DIR/Library/Containers/com.docker.docker/Data/vms/0/data/Docker.raw" ]; then
  ls -lh "$HOME_DIR/Library/Containers/com.docker.docker/Data/vms/0/data/Docker.raw" 2>&1 || true
  du -sh "$HOME_DIR/Library/Containers/com.docker.docker" 2>&1 || true
fi

section "Notes"
cat <<'NOTES'
- This report is read-only.
- Run clean_safe.sh --dry-run before any cleanup.
- Docker.raw, Claude VM bundles, browser profiles, dirty worktrees, and personal Downloads files require explicit approval.
NOTES
