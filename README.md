# agent-skills

A tool-neutral collection of **standalone** agent skills for Claude Code, Codex, and
compatible skill-discovery directories.

Each skill lives in its own folder with a tool-neutral `SKILL.md` and optional local assets
such as scripts, references, examples, or templates. Skills are installed independently, so a
machine can use one skill without taking the rest of the repo.

Skills owned by another repository, vendored third-party skills, and generated tool caches are
out of scope.

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

More skills can be added under `skills/<name>/`.

## Contributing and Security

This repository is public. Before opening a pull request, read
[`CONTRIBUTING.md`](./CONTRIBUTING.md) and [`SECURITY.md`](./SECURITY.md). Do not commit
secrets, private URLs, internal logs, generated state, or machine-local config.
