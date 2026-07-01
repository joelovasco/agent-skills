# Security Policy

## Supported Versions

Security fixes target the current `main` branch.

## Reporting a Vulnerability

Do not open a public issue for a vulnerability or leaked secret. Use GitHub's private
vulnerability reporting for this repository when available, or contact the maintainer
through the repository owner profile.

Include:

- A short description of the issue.
- The affected skill, script, or documentation path.
- Safe reproduction steps that do not include secrets, private URLs, internal logs, or
  machine-local data.

## Public Repository Rules

- Do not commit tokens, credentials, private URLs, internal logs, customer data, generated
  state, or local machine config.
- Example files must use placeholder values and the `.example` suffix when appropriate.
- Local config belongs outside this repository, such as under `~/.config/<skill>/`.
