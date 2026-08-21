# Contributing

Contributions are welcome through pull requests. This repository is public, so keep all
changes safe to publish.

## Guidelines

- Keep each pull request focused on one skill, script, or repo-maintenance change.
- Do not include secrets, tokens, private URLs, internal logs, customer data, or
  machine-local paths.
- Keep skill instructions in `skills/<name>/SKILL.md`; do not add per-skill README files.
- Put reusable scripts under `scripts/`, detailed policy/reference material under
  `references/`, and generated local config outside this repository.
- Use `*.example` files for examples that users copy into local config.

## Local Checks

Before opening a pull request, run:

```bash
find . -path ./.git -prune -o -name '*.sh' -print0 | xargs -0 bash -n
./install.sh --dry-run
bash skills/machine-health/scripts/configure.sh --print >/tmp/machine-health-config.txt
```

The maintainer controls what merges to `main`.
