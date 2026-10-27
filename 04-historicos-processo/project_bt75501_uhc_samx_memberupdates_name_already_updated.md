---
name: project-bt75501-uhc-samx-memberupdates-name-already-updated
description: "BT-75501 UHC_SAMx_MemberUpdates - EE not found on name change already applied on portal; fix + enhancement tested in Staging with real Prod transactions, PR #3302 opened 2026-09-09"
metadata: 
  node_type: memory
  type: project
  originSessionId: fd26cff3-c431-41f8-b169-74ecb059d3d2
  modified: 2026-09-09T22:56:50.294Z
---

**Ticket:** BT-75501 (reported by Tammy Borders, priority Lowest). `UHC_SAMx_MemberUpdates` fails with `BusinessRuleException("EE does not exist on carrier portal")` when a member-name-change case is reprocessed after the name was already applied to the real UHC portal (e.g. a prior partial run saved the name but failed later, or a manual fix). Root cause: `ProcessTransaction.xaml` searches only by the *previous* name (BBO-3581 logic) and throws immediately if that search comes up empty, never checking whether the *current* name is already on the portal.

**Branch:** `BT-75501-UHC-SAMx-MemberUpdates-name-already-updated`, created off `develop` (not pushed yet — user explicitly said "não abre PR ainda", 2026-09-09).

**Commits so far (all local, unpushed):**
1. `[BT-75501] Fix: retry EE search with current name when previous-name search fails` — adds a second `gus:CheckIfEmployeeExists` call (by current name) when the first search (by previous name) fails on a name-change case; if found, proceeds to `EditEmployee` instead of throwing. `project.json` bumped 5.20.5 → 5.20.6.
2. `[BT-75501] Add Info-level logging around the name-already-updated retry` — two `ui:LogMessage Level="Info"` around the retry, so Orchestrator/RobotLogs shows whether the fix path fired and its outcome.
3. `[BT-75501] Skip re-entering/re-saving an already-applied name change` — when the retry confirms the name is already on the portal **and** the pending update is name-only (no bundled address/email/gender/birthday), skip `EnterSubscriberInformation` and `CompleteMemberUpdate`'s save-and-verify entirely and go straight to the confirmation screenshot. Added `nameAlreadyUpdated` Boolean variable in the `Process Layer` Sequence.

**Why commit 3 was needed:** discovered live in Staging that when the retry succeeds but the process still runs the normal `EditEmployee → EnterSubscriberInformation → CompleteMemberUpdate` flow, `CompleteMemberUpdate` can fail with `"Member update is not successful"` — because nothing was actually changed/saved (name was already correct), so the "Member updated successfully" confirmation banner never appears. This is exactly what Tammy's ticket asked for: *"it could just take a Confirmation SS and mark it as successful"* instead of re-entering/re-saving.

**Staging test results (tenant Staging, folder `Benefits/CarrierAutomation`, queue `UHC_SAMX_MemberUpdates` — note the casing mismatch vs the Prod/code name `UHC_SAMx_MemberUpdates`):**
- Test 1 — real Prod case `500R7000017kHSnIAM` (Rajanee Hamilton, `first_name` change "Raja'Nee"→"Rajanee", group 1674920, "Vocal Justice"): retry fired, found by current name, **Transaction successful** end-to-end (before commit 3 existed — went through the full EditEmployee/EnterSubscriberInformation/CompleteMemberUpdate path and it happened to pass).
- Test 2 — real Prod case `500R7000017JIb2IAG` (Brianna Guarin, `last_name` change "Josewski"→"Guarin", group 1647949, "Melissa A Goodpaster DDS PLLC"): retry fired, found by current name, but **failed** at `CompleteMemberUpdate` with `"Member update is not successful"` (same failure reason as the original Prod failure on 2026-08-29 — meaning the original run had already silently applied the name change to the portal back then, and just failed on the confirmation step). This is what triggered commit 3.
- Re-run of Test 2 with commit 3 applied: item re-added to Staging queue (key `4c185938-68a4-45a7-a5ee-0d2364349f03`), **awaiting result** — user is about to run it in Studio.

**Final Staging tally (2026-09-09, 4 real Prod transactions replayed):**
1. Rajanee Hamilton, `first_name` (case `500R7000017kHSnIAM`) → **Successful** (ran before commit 3 existed, went through full EditEmployee/EnterSubscriberInformation/CompleteMemberUpdate path, happened to pass).
2. Brianna Guarin, `last_name` (case `500R7000017JIb2IAG`) → **Successful** after commit 3 (skip-CompleteMemberUpdate path fired).
3. Caroline Kozak→Allen, `last_name` (case `500R7000017YBMNIA4`) → **Successful**, same skip-path fired again with different data.
4. Maria Percy, `first_name` (case `500R7000017SUWeIAO`) → **Failed**, but unrelated/pre-existing: blew up in `CheckMemberUpdateCaseData` with `"Employee Gender is null in SFDC"` — same reason as the original 2026-09-01 Prod failure, fails before ever reaching `CheckIfEmployeeExists`/the retry logic, so it never exercises this fix at all. Not a regression.

3 of 4 successful, both fix paths (with-retry-only and with-retry-plus-skip-save) confirmed on real portal data — comfortably above the checklist's 2-3 transaction minimum.

**Status as of 2026-09-09: code DONE, validated in Staging, PR #3302 opened** (https://github.com/Gusto/biztech-uipath-rpa/pull/3302), branch pushed to origin. Before pushing, merged `origin/develop` into the branch (it was stale — two-dot diff was picking up unrelated `iSolved_EE_Details` changes merged into develop after branch creation; see [[feedback_shared_root_dependencylock_conflicts]]-style Buildkite two-dot-diff issue). Post-merge diff is clean: only `ProcessTransaction.xaml` + `project.json` (5.20.5→5.20.6) for UHC_SAMx_MemberUpdates. PR body used checklist only, no transaction-ID table (per [[feedback_pr_no_claude_signature_no_tx_table]] on the table; the Co-Authored-By/Claude Code footer WAS added per current session's explicit attribution override instruction, superseding that memory's "no AI signature" part for commits/PRs going forward).

**Pending / next steps:**
1. **Watch Buildkite on PR #3302** for the pre-existing, unrelated `UI-DBP-006` build error in `CompleteMemberUpdate.xaml` (`Top level selector used outside scoped containers`, on "Employee Accordion"/"State"/zip-code/"Save"/"Member updated successfully" selectors) — confirmed pre-existing on `develop` (reproduced with the fix stashed out too), not caused by this work. If it fails Buildkite, this needs a separate fix before merge; flag to Sri/Oscar if it blocks.
2. Still outstanding, not blocking the PR: **"prova real"** — manually check the actual UHC portal / the uploaded `Confirmation.png` screenshots in the `Transactional Screenshots` bucket (Staging, folder `Benefits/CarrierAutomation`) to confirm the bot's confirmation screenshots genuinely reflect the real portal state for the Guarin/Kozak cases, not a false positive.
3. Credential fix side-quest (see [[feedback_getcredential_support]]): Staging's `Credential_UHC_SAMx_MOps` asset was stale — user already updated it manually in the Orchestrator UI mid-session using the value read from Production via a temporary `GetRobotCredential` block (added to and reverted from `InitAllApplications.xaml`, never committed). Login now works in Staging.
4. Staging queue `UHC_SAMX_MemberUpdates` currently holds the 4 replayed test items (3 Successful, 1 Failed-unrelated per the tally above) — fine to leave as historical record, or clean up if the team prefers an empty queue.
5. Still need: Jira comment on BT-75501 linking PR #3302 — not done yet, do if asked.

**How to apply:** when resuming this ticket, read this memory first, then check `git log` on the branch to confirm which commits actually landed (this memory may be ahead of or behind actual git state if the session dropped mid-edit).
