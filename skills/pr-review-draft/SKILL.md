---
name: pr-review-draft
description: Use when drafting or preparing a GitHub pull request review, reviewing a specific PR, turning PR evidence into findings, or creating review text without immediately posting it.
---

# PR Review Draft

Produce evidence-backed PR review text for a human to inspect before posting; this is not a
GitHub draft pull request.

Prompt-first and OS-agnostic: no bundled scripts, local automation directories, or required
shell environment.

## Required Flow

1. Identify the review target: PR URL, `owner/repo#number`, branch, pasted diff, or files.
2. Gather current evidence from the best host source.
3. If live PR access is unavailable and no diff was provided, ask for context.
4. Inspect changed code, nearby implementation/tests/config, and applicable repo guidance
   such as `AGENTS.md`, `CLAUDE.md`, `CONTRIBUTING.md`, or PR templates.
5. Draft findings first, ordered by severity, with exact file/line references when available.
6. Include open questions only when they affect review confidence.
7. If there are no findings, say so and note real verification gaps.
8. Do not post, approve, request changes, or write files unless explicitly asked.

## Evidence Sources

Prefer direct current sources:

- GitHub MCP, app, connector, or API tools.
- Built-in review tools or other PR-review skills.
- A user-supplied PR URL or `owner/repo#number`.
- A local checkout or branch when asked to review local work.
- A pasted diff, patch, or file set.

Use memory only as a pointer. Stale drafts, old diffs, and remembered PR state are not
authoritative.

## Host Review Tools

If the host has a built-in review tool or another PR-review skill, use its output as evidence.
Do not let it replace this skill's format. Reconcile host output into `Findings`,
`Open Questions`, and `Notes`.

## Draft Format

Always use these exact headings, even for stdout or chat:

```markdown
Findings
- [severity] `path/to/file.ext:line` Bug/risk, why it matters, and smallest useful fix direction.

Open Questions
- Only questions that materially affect whether the review should block.

Notes
- Reviewed {evidence source} at {head SHA, or "no SHA available"}.
- Test gaps, verification limits, PR status/checks, an approve / do-not-approve
  recommendation for the human to act on, or "No findings".
```

Severity is one of `blocker`, `major`, `minor`, or `nit`. Use no other labels, and order
findings from `blocker` down.

The first `Notes` line is required. Name the source you actually read (live PR, local
branch, pasted diff, host review tool) and the head SHA it was at, so the reader can judge
how current the draft is. If you could not determine the head, say so explicitly rather
than omitting the line.

Do not append unheaded status or approval text after the template. Keep the draft concise.

## No-Findings Case

If no issues are found, say:

```markdown
No findings.

Reviewed {evidence source} at {head SHA, or "no SHA available"}.

Verification gaps: {only real gaps, or "None beyond the reviewed diff."}
```

## Guardrails

- Read-only by default.
- Do not submit reviews, approvals, comments, or requests for changes unless asked.
- An approve / do-not-approve recommendation in `Notes` is guidance for the human, not an
  action. Never act on your own recommendation.
- Before posting or approving later, re-check the current PR head and diff.
- Do not invent line numbers; cite file/function if line anchors are unavailable.
- Do not rely on shell commands as part of the skill contract.
- Do not use OS-specific paths or assumptions.
- Do not create artifacts unless asked.
- Keep wording direct and friendly, especially for draft comments.

## Trigger Phrases

- "draft a PR review"
- "review this PR with pr-review-draft"
- `use pr-review-draft to review {url}`
- "create a review draft"
- "friendly review comment"
- "find issues in this diff"
- "should I approve this PR?" / "approve this PR?"

## Not a Trigger

Do not invoke on a bare approval question ("approve?", "lgtm?", "ship it?") unless a PR,
diff, or branch is already the active subject. Approval language about designs, plans,
budgets, tickets, or deploys is out of scope. When the subject is ambiguous, ask what
should be reviewed instead of producing a draft.
