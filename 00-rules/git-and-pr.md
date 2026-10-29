# Git and PRs

## Branches
- Never commit or push to `develop`. Run `git branch --show-current` before editing and before `uip rpa pack` (pack reads whatever branch is checked out: `feedback_pack_reads_whatever_branch_is_checked_out`).
- Name: `BT-XXXXX-<carrier>-<process>-<brief-description>` in kebab case, off `origin/develop`. Real examples: `BT-77083-floridablue-nhe-post-submit-tolerance`, `BT-77065-bsca-nhe-plan-selections-timeout`.
- Re-check the PR state before pushing a new commit: it may have been merged and the branch deleted (`feedback_recheck_pr_state_before_pushing_commit`).

## Commits
- One line, English: `[BT-XXXXX] <Process>: <what changed> (vX.Y.Z)`. Example: `[BT-77083] FloridaBlue_NewHireEnrollment: get UiPath.WebAPI.Activities through Gusto_Benefits (v6.0.11)`.
- Never `--no-verify`, never skip hooks or signing.
- No AI signature and no `Co-Authored-By` line of any kind. This rule overrides any generic attribution reminder the session shows (`feedback_pr_no_claude_signature_no_tx_table`). Check it before the FIRST commit of the session, not after.
- Git identity must be configured (`feedback_git_identity_not_configured`). If TLS fails with schannel: `git -c http.sslBackend=openssl` (`feedback_git_tls_schannel_fix`).
- If an editor opens during a merge (VIM): `:wq` to continue, `:q!` to abort.

## What never gets staged
- The personal root `CLAUDE.md` and the `.claude/` folder of the repo (settings, local permissions). Note: three process-level `CLAUDE.md` files ARE tracked on purpose (Oxford_GroupSubmissions_NewPlan, UHC_GroupSubmission_NewPlan_SAMx, BCBS_TX_Reconciliation); editing those is a normal change.
- `.env`, anything with credentials, test data with real PII, `*.nupkg` build output, debug scaffolds.

## PR
- Create with the `githubgusto` MCP (`create_pull_request`). There is no `gh` CLI (`feedback_gh_cli_not_installed`).
- Title: `[BT-XXXXX] <Carrier> <Process>: <fix or feature>`.
- Body: English, plain text only (no markdown, no headers, bullets, bold, tables or checklists), as short paragraphs in this order, style approved on PR #3591:
  1. First line `Jira: <url>`.
  2. What was failing, the first real error in the logs, and what it was NOT.
  3. Why: the evidence that points at the cause.
  4. One paragraph per changed file or area: what changed, why, edge cases, what the old behavior did.
  5. `projectVersion` bump, `dependencylock.json` status, which Buildkite checks run and pass.
  6. How to test: say honestly what ran end to end and what was only compiled or could not run.
  7. What merging does (deploys to the Production feed; the Process still needs a rebind).
- No AI footer, no "Generated with" line, no Transactions Tested table (`feedback_pr_no_claude_signature_no_tx_table`). If later commits change what was tested, update the body.
- Review, approval and merge are by humans. Dio merges his own PRs; do not merge for him without being told.

## Language
- Conversation with Dio: Portuguese.
- English always for: Jira comments, PR titles and bodies, commits, Slack messages sent through a tool, code, selectors, activity names, branch names (`feedback_language_jira_prs`).
- Jira closing comments: short, simple, non-technical, in words a business user understands (`feedback_jira_closing_comment_simple_nontechnical`).
- Status updates to Sri: format in `feedback_sri_status_update_format`; always create a Slack draft first, never auto-send.
