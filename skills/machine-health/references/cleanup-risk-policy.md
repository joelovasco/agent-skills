# Cleanup Risk Policy

## Safe To Report

Always safe:
- Disk usage: `df -h`, `du`
- Memory pressure: `memory_pressure`, `vm_stat`
- Process listings: `ps`, `lsof`
- Git worktree listings and statuses
- Docker status and disk usage
- Time Machine local snapshot listings

## Safe To Delete With `clean_safe.sh --apply`

Only rebuildable/generated data:
- `node_modules` in stale worktrees selected by the script
- `.next`, `build`, `dist`, `coverage`, `.tmp`
- npm `_cacache`, `_npx`, `_logs`
- Cypress, Playwright, Puppeteer, Yarn, uv caches
- JetBrains, Spotify, VS Code update, Postman update, node-gyp, TypeScript, pip, Homebrew caches
- Git prunable worktree metadata via `git worktree prune`

## Approval Required

Ask before deleting:
- Dirty worktrees or untracked files
- Whole repo checkouts
- Anything in `Downloads` except after a named review batch
- Trash contents
- Docker `Docker.raw`, images, volumes, or container data
- Claude VM bundles or Claude app-support data
- Browser profiles, app support folders, mail/messages/photos, iCloud data
- Any file that looks personal: documents, photos, videos, PDFs, HARs, archives with unknown contents

## Process Handling

Safe to stop only when identity is clear:
- stale Playwright MCP/browser automation
- stale local dev servers from old work
- stale test runners

Do not kill:
- active Claude/Codex processes
- Teams/Chrome/user apps unless the user asks
- VM processes unless `lsof` proves ownership and the user approves

## Verification

After cleanup:
- Run `df -h "$HOME"`.
- Run `tmutil listlocalsnapshots /`.
- Run `memory_pressure` for memory work.
- Confirm no cleanup commands are still running with `ps`.
