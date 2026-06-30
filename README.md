# agent-skills

Personal, **standalone** skills for Claude Code and Codex — the ones we built by hand that
previously lived untracked across `~/.claude/skills`, `~/.codex/skills`, and `~/.agents/skills`.

This repo borrows the *structure* of [obra/Superpowers](https://github.com/obra/superpowers)
(per-skill folder, one tool-neutral `SKILL.md`, symlink-based install) but **not** its
coupling: Superpowers is one interdependent workflow shipped as a single plugin; these are
independent utilities, each installed on its own.

> The 14 `thread-*` skills are **not** here — they're owned by the `thread-tracker` repo.
> Vendored third-party skills (`superpowers`, Codex `.system/*`) are also out of scope.

## Layout

```
skills/<name>/SKILL.md      # one tool-neutral skill per folder (+ scripts/, references/)
harness/<name>/             # shared engines a skill calls (e.g. the PR-review Python package)
templates/skill-template/   # scaffold for a new skill
install.sh                  # per-skill symlink installer
.claude-plugin/             # thin Claude marketplace adapter
.codex/INSTALL.md           # Codex install instructions
```

Paths inside a skill are **relative to the skill folder**; secrets/state are never committed
(see `.gitignore`).

## Install

```bash
git clone https://github.com/joelovasco/agent-skills.git ~/Documents/agent-skills
cd ~/Documents/agent-skills

./install.sh --dry-run        # preview
./install.sh                  # symlink every skill into the tools' discovery dirs
./install.sh machine-health   # or just one skill
```

`install.sh` symlinks each `skills/<name>` into whichever of `~/.claude/skills`,
`~/.codex/skills`, and `~/.agents/skills` exist on the machine. Update with `git pull` — the
symlinks keep pointing at the working tree, so there's nothing to re-run unless you add a skill.

## Skills

| Skill | What it does |
|-------|--------------|
| `machine-health` | Report + safely clean local macOS disk / memory / caches / worktrees / Docker. |

_(more migrated per the plan in `planning-docs/agent-skills/`)_
