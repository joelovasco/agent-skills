---
name: skill-name
description: Use when <the trigger condition> — keep this specific; it's how the agent decides relevance.
---

# Skill Name

One-paragraph summary of what this skill does and when to reach for it.

## Required Flow

1. <First step — reference scripts relatively, e.g. `./scripts/do-thing.sh`.>
2. <Next step.>
3. <Verify / report.>

## Notes

- Keep paths relative to this skill folder so it works through any install symlink.
- Put rebuildable helpers in `./scripts/`, longer reference material in `./references/`.
- If this skill calls a shared engine, reference it under the repo's `harness/<name>/` and
  resolve the path from this file's real location (`readlink`), never a hardcoded `$HOME` path.
