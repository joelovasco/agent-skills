# machine-health config — EXAMPLE / template.
#
# The real config lives at ~/.config/machine-health/config.sh (outside this repo).
# Generate it automatically with:  scripts/configure.sh --apply
# or copy this file there and edit by hand. Only existing paths are ever acted on.

# Where to look for git repos (worktree audit/prune, generated-output cleanup).
# Empty => the built-in candidate roots are used (~/Documents, ~/code, ~/src, ~/projects, ...).
MH_SCAN_ROOTS=()

# Containers that hold standalone worktrees (tooling-managed worktree homes).
# Empty => default (~/.config/superpowers/worktrees if present).
MH_WORKTREE_DIRS=()

# Explicit repos to audit/prune. Empty => auto-discover under MH_SCAN_ROOTS.
MH_REPOS=()

# Extra rebuildable caches beyond the universal baseline (appended). Usually empty.
MH_EXTRA_CACHES=()

# ============================================================================
# PROTECTED REPOS — nothing is protected by default.
# Cleanup (worktree prune, generated output, node_modules) NEVER skips a repo
# unless you list it here, by basename or full path. Populate to shield a
# critical local checkout from automated cleanup, e.g.:
#   MH_PROTECT_REPOS=( "my-critical-repo" "$HOME/Documents/some.important.repo" )
# ============================================================================
MH_PROTECT_REPOS=()
