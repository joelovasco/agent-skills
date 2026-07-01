---
name: machine-health
description: Use when checking or improving local macOS disk space, memory pressure, stale workspaces, Git worktrees, generated build output, package caches, Downloads clutter, Docker disk usage, or local Time Machine snapshots.
---

# Machine Health

Source of truth for Claude and Codex machine-hygiene work. All paths below are relative to
this skill folder, so it works through whichever install symlink the tool discovered it by.

## First-run setup

This skill ships with **no machine-specific paths**. On a new machine, generate a local
config so it knows your repos / worktree dirs / caches:

1. `scripts/configure.sh --print` — discover and review the proposed config (changes nothing).
2. `scripts/configure.sh --apply` — write it to `~/.config/machine-health/config.sh`.

Re-run any time your repos change. Without a config, the scripts fall back to auto-discovery
under common dev roots. **Nothing is protected from cleanup by default** — add repos to
`MH_PROTECT_REPOS` in the config to shield them.

## Workflow

1. Read `references/cleanup-risk-policy.md` before any cleanup.
2. **Discovery pause.** Every script leads with a one-line discovery summary, e.g.
   `43 directories discovered, 0 protected  [auto-discovery, no config file]`. Surface that
   count to the user, then present an **arrow-navigable selection** (the host's native
   choice picker — in Claude Code that is the `AskUserQuestion` checkbox list, not a prose
   yes/no) with the options:
     - **View full list** — expand all discovered + protected repos (re-run with
       `MH_SHOW_REPOS=1`, which prints the full banner) before proceeding.
     - **Continue** — proceed to the disk/memory/cleanup evidence without listing.
   Wait for the selection. Never silently operate on an unseen repo set.
3. Run `scripts/health_report.sh` first. Treat the report as evidence.
4. If worktrees are involved, run `scripts/worktree_audit.sh`.
5. For safe generated clutter only, run `scripts/clean_safe.sh --dry-run` first.
6. Run `scripts/clean_safe.sh --apply` only after reviewing the dry run and respecting
   approval boundaries.
7. Verify with `df -h "$HOME"`, `tmutil listlocalsnapshots /`, and — for memory work —
   `memory_pressure`.

## Operating Rules

- Prefer reports over guesses.
- Preserve dirty worktrees and personal files.
- Treat destructive cleanup as a confirmation boundary; never delete approval-required items
  automatically (see `references/cleanup-risk-policy.md`).
- Use `git worktree remove` for registered worktrees; do not `rm -rf` worktrees blindly.
- Move personal-review candidates to a dedicated Trash folder before permanent deletion.
- Treat Docker `Docker.raw`, Claude VM bundles, browser profiles, and app-support data as
  approval-required.
- Stop stale dev/test/browser-automation processes only when the process identity is clear.
