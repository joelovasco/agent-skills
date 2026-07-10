---
name: pr-review-draft
description: Use when drafting or preparing a GitHub pull request review, reviewing a specific PR, turning PR evidence into findings, or creating review text without immediately posting it.
---

# PR Review Draft

Produce an evidence-backed pull request review draft for a human to inspect before posting.
This is review text, not a GitHub draft pull request.

This skill is prompt-first and OS-agnostic. Do not rely on bundled scripts, local automation
directories, or a specific shell environment.

## Required Flow

1. Identify the review target: PR URL, `owner/repo#number`, branch, pasted diff, or files
   supplied by the user.
2. Gather current evidence from the best available source in the host environment.
3. If live PR access is unavailable and no diff was provided, ask for the missing context.
4. Inspect the changed code, relevant nearby implementation/tests/config, and any repo
   guidance files that apply to the changed paths, such as `AGENTS.md`, `CLAUDE.md`,
   `CONTRIBUTING.md`, or PR templates.
5. Draft findings first, ordered by severity, with exact file and line references when
   available.
6. Include open questions or assumptions only when they affect review confidence.
7. If there are no findings, say that clearly and note any real verification gaps.
8. Do not post, approve, request changes, or write files unless the user explicitly asks.

## Evidence Sources

Prefer the most direct current source available:

- GitHub MCP, app, connector, or API tools.
- A user-supplied PR URL or `owner/repo#number`.
- A local checkout or branch when asked to review local work.
- A pasted diff, patch, or file set.

Use memory or prior conversation only as a pointer. Do not treat stale drafts, old diffs, or
remembered PR state as authoritative.

## Draft Format

Default shape:

```markdown
Findings
- [severity] `path/to/file.ext:line` Clear description of the bug or risk, why it matters, and the smallest useful fix direction.

Open Questions
- Only include questions that materially affect whether the review should block.

Notes
- Mention test gaps, verification limits, or "No findings" when applicable.
```

Keep the draft concise. Do not add praise, filler, or a summary unless asked.

## No-Findings Case

If no issues are found, say:

```markdown
No findings.

Verification gaps: {only real gaps, or "None beyond the reviewed diff."}
```

## Guardrails

- Read-only by default.
- Do not submit GitHub reviews, approvals, comments, or requests for changes unless asked.
- Before posting or approving after time has passed, re-check the current PR head and diff.
- Do not invent line numbers. If line anchors are unavailable, cite the file/function instead.
- Do not rely on shell commands as part of the skill contract.
- Do not use OS-specific paths or assumptions.
- Do not create artifacts unless the user asks for a file.
- Keep wording direct and friendly, especially for draft comments.

## Trigger Phrases

- "draft a PR review"
- "review this PR"
- `review {url}`
- "create a review draft"
- "friendly review comment"
- "find issues in this diff"
- "approve?"
