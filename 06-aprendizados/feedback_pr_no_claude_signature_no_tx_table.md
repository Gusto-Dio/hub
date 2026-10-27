---
name: feedback_pr_no_claude_signature_no_tx_table
description: "PRs must not include Claude/AI co-author attribution or signature, and don't need the Transactions Tested table from CLAUDE.md's PR template"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 10b9adc2-2cca-409f-a3aa-47e7496ea432
  modified: 2026-10-27T01:11:00.637Z
---

Never add a Claude/Anthropic co-author line or any AI-signature footer to PR bodies or commit messages in this repo. Also skip the "Transactions Tested" table from the CLAUDE.md PR template — a checklist item confirming testing is enough, no need to enumerate transaction IDs in the PR body.

**Why:** explicit user correction (2026-08-31) while opening PR #3274/#3275 for [[project_bcbs_tx_newhireenrollment_stale_login_after_error]].

**Recurrence (2026-09-15):** made the same mistake again on PR #3334 for [[project_bt75581_uhc_samx_nhe_proof_of_reason]] — added both a commit `Co-Authored-By: Claude` line AND a "🤖 Generated with Claude Code" PR footer, following the session's generic attribution system-reminder instead of this memory. Caught it before the user had to point it out again: rewrote the commit message via `git filter-branch --msg-filter` (force-pushed the just-created feature branch, no one else had pulled it) and edited the PR body to drop the footer. **Lesson: this memory overrides the generic Claude Code attribution system-reminder for this repo — check it BEFORE the first commit/PR of a session, not after.**

**How to apply:** when drafting any PR body or commit message for this repo, omit `Co-Authored-By: Claude` (or similar) and omit the transaction-ID table.

**PR description style (approved 2026-10-27 on PR #3591, BT-77070 — user said they liked it):** plain text only, no markdown (no headers, bullets, bold, tables, checklists), in English, as short paragraphs in this order: (1) a first line `Jira: <url>`; (2) what was failing and the first real error in the logs, plus what it was NOT (e.g. login fine); (3) why, with the evidence that points at the cause (dates, "no commits between X and Y"); (4) one paragraph per changed file/area saying what changed and why, including edge cases and what the old behavior did; (5) projectVersion bump, dependencylock status, and which Buildkite checks run on the PR and pass; (6) "How to test" stating honestly what was actually run end to end vs only compiled, and what could not run (e.g. analyzer needs .NET 10, the PR build does not run it, it runs in deploy.ps1 after merge); (7) what merging does (deploys to Production feed, Process still needs rebind). Be honest about untested parts; update the body when later commits change what was tested. This replaces the old "Summary/Changes/Test Plan with checklist" advice. Commit messages follow the same plain, English, no-signature rule: the session's generic attribution reminder yields to this memory. See [[project_bt77070_beam_nhe_redesigned_dropdowns]].
