# Installing agent-skills for Codex

These skills install via native skill discovery — clone and run the installer, which symlinks
each skill into the dirs your tools read (`~/.codex/skills`, `~/.claude/skills`,
`~/.agents/skills`).

## Prerequisites
- Git, bash

## Installation
1. **Clone:**
   ```bash
   git clone https://github.com/joelovasco/agent-skills.git ~/Documents/agent-skills
   ```
2. **Install (symlink) the skills:**
   ```bash
   cd ~/Documents/agent-skills
   ./install.sh --dry-run   # preview
   ./install.sh             # all skills — or: ./install.sh <skill-name>
   ```
3. **Restart Codex** (quit and relaunch the CLI) to discover the skills.

## Updating
```bash
cd ~/Documents/agent-skills && git pull
```
Symlinks point at the working tree, so a pull is enough. Re-run `./install.sh` only after
**adding** a new skill.

## Uninstall
```bash
./install.sh --uninstall            # remove all symlinks
./install.sh --uninstall <skill>    # remove one
```
