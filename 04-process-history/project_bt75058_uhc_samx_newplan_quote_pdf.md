---
name: project_bt75058_uhc_samx_newplan_quote_pdf
description: "BT-75058 UHC_SAMx_GroupSubmissions_NewPlan — spike of 'Unable to download Quote PDF' failures since ~2026-08-17/18. Root cause traced to EnterCompanyInfo.xaml's Save-As-dialog-only detection (~17min retry budget); no code fix applied — Staging debug + an overnight Production run (2026-08-20/21, 13 transactions, zero Quote PDF recurrences) confirmed it was a transient environment issue. TICKET CLOSED 2026-08-21 (Done) after posting the confirming comment; informal monitoring continues, no code changed on branch BT-75058-UHC-SamX-GroupSubmissions-NewPlan-quote-pdf-fix."
metadata:
  type: project
  originSessionId: ead6d013-b01d-4e2a-8c81-462c1d24e0f4
  modified: 2026-08-21T15:02:56.665Z
---

**Ticket:** BT-75058 — reporter Bri Boyer, priority High, status In Progress, assigned to Dio. Impacted automation: `UHC_SAMx_GroupSubmissions_NewPlan` (repo path: `Processes/Benefits/CarrierAutomations/GroupSubmission/UnitedHealthcare/SamX/UHC_GroupSubmission_NewPlan_SAMx`). Reported: spike in failures for "Unable to download Quote PDF...", 18/21 UHC New Plan Carrier Orders failed on 2026-08-18. Reporter noted some recordings show the download actually completing despite the bot failing the order with this error.

**Branch:** `BT-75058-UHC-SamX-GroupSubmissions-NewPlan-quote-pdf-fix`, cut fresh from `origin/develop` on 2026-08-19/20. (Unrelated cosmetic BT-74292 diff on `BSCA_GroupSubmissions_GroupLevel/ProcessTransaction.xaml` was stashed before switching, not lost — stash message "BT-74292 cosmetic Studio reserialization noise (ProcessTransaction.xaml)".)

## Root cause — confirmed via uipath-troubleshoot skill (2026-08-19/20)

**Source** (`ProcessLayer/EnterCompanyInfo.xaml:2715-2822`): the workflow detects "Quote PDF download succeeded" **only** by checking whether the native Windows **"Save As"** dialog opened (`ui:UiElementExists` on `<wnd app='chrome.exe' cls='#32770' title='Save As' />`). If not detected within a retry loop (12 attempts × 5s delay, reclicking "Download" each time), it throws `BusinessRuleException("Unable to download Quote PDF because the portal did not open the Save As window after 12 Download attempts spaced 5 seconds apart.")`. There is no fallback detection (e.g. checking the Downloads folder for the file).

**Investigation notes:**
- The ticket's "transaction IDs" (`f7bdebed...`, `a3e7b58e...`) are the queue item's `Reference` field (`CarrierOrderSubmissionRequestUUID`), NOT the queue item `Key` — `uip or queue-items get`/`uip or jobs get` on those IDs directly 404. Had to list queue `UnitedHealthCare_GroupSubmissions_NewPlans_SAMx` (key `c6540bc9-85cc-4ba1-b023-532ed5a4b7a4`, folder `Benefits/CarrierAutomation` key `fe1ead56-e4c7-4b91-b434-7df5ba4ebb70`) and match on `Reference` to find the real `Key`s (`e3c0ea38-f7b8-401a-a22a-1be02b3729bd` and `694952e0-6688-4586-8bd9-31b9973abef1`).
- Both example items were processed by the **same** `ExecutorJobKey` (`2751f13d-d6be-4441-8214-58a37044ec71`) — one long-running Enhanced ReFramework job looping many transactions, not separate jobs.
- `ProcessingExceptionType: BusinessException`, `SecondsInPreviousAttempts` ~1048s/1060s — matches the 12×5s retry math.
- **Categorized all 14 currently-Failed items from 2026-08-18**: 9/14 are this exact Quote PDF error (dominant, ~64%), 3/14 are an unrelated "UHC portal requires minimum 2 for ATNE and FTE" data-validation error, 1/14 a generic selector-not-found, 1/14 "Order is no longer in Automation Queue" — the latter 3 types are out of scope for this ticket.
- **Confirmed this is a genuine new regression, not chronic**: sampled 4 older Failed items (2026-08-05 to 2026-08-10) — none mention Quote PDF/Save As, all different error types. The failure mode started ~2026-08-17/18.
- **Data gap (cannot resolve via `uip` CLI)**: `uip or jobs traces` returned empty ("only recorded for Agent-type processes" — this is a standard RPA process). Bri's screen recordings are not accessible via the `uip` CLI (outside this troubleshooting skill's tool boundary). So it's **unconfirmed** whether the underlying trigger is (a) a Chrome setting/policy change on the robot machine (e.g. "Ask where to save each file before downloading" toggled off, so Chrome now saves silently to the default Downloads folder instead of prompting) or (b) a UHC portal-side change to how it serves the Quote PDF.

## Next steps

1. Get Bri's recording for one of the failing transactions to confirm visually whether the Save As dialog renders at all.
2. If Chrome-setting root cause confirmed: either fix the Chrome/robot-machine config, or (more robust) add a fallback detection in `EnterCompanyInfo.xaml`'s download-retry logic — e.g. also check the local Downloads folder for the expected filename before declaring failure — instead of relying solely on the Save As dialog.
3. No code has been written yet for this ticket — investigation only so far, no XAML touched.
4. See also [[project_bt74292_bsca_grouplevel_plan_modifications]] for the unrelated ticket whose branch was set aside (stash) to make room for this one.

## Update 2026-08-20/21 — retry budget re-measured, no fix applied, monitoring instead

**Re-measured the actual `While_RetryQuoteDownloadUntilSaveAs` budget in `EnterCompanyInfo.xaml`** (read the real XAML instead of relying on the earlier summary): it's NOT "12 attempts × 5s = 60s". Each iteration is delay 5s + recheck (≤10s) + [if still closed] click retry + allow-multi-download check (≤10s) + recheck (≤10s) ≈ up to 35s/iteration × 12 = **up to ~17 minutes** before the `Throw_QuoteDownloadSaveAsNotOpen` BusinessRuleException. This matches the `SecondsInPreviousAttempts` (~1048s/1060s) seen in the original Prod failure logs almost exactly — those failures exhausted the full ~17min budget, not a short 60s one.

**Live evidence pulled in this session (user ran a Studio debug session in Staging, 2026-08-20 23:35–00:33 local, 4 transactions):** the Save As dialog was genuinely slow on the first transaction — `SaveFileFromNewTab` took 460s (~7.7min) after a `Retry Type Into 'File Name'` warning at the 00:01:11 mark, then succeeded at 00:06:48. All 4 transactions in that debug run completed the full flow successfully (`Transaction successful` in Main.xaml logs each time).

**Revised conclusion:** since the debug run succeeded comfortably inside the ~17min existing budget, a plain timeout/attempt-count increase would NOT have fixed the real Prod failures, which already exhausted that same ~17min budget without the dialog ever appearing. This re-supports the original Chrome-setting hypothesis (dialog never opens at all in the failing cases, matching Bri's note that some recordings show the download completing despite the bot failing) rather than "just needs more time." **Next real fix candidate (not implemented):** a Downloads-folder fallback — poll the robot's default Chrome download folder for the new PDF and move/rename it to `in_QuoteFilePath` when no Save As dialog ever appears, instead of only ever waiting on the dialog.

**Decision (user, 2026-08-20):** don't code that fallback yet. Re-ran the bot directly in Production instead; it processed transactions normally. Posted two English comments on BT-75058:
1. "Re-ran the bot in Production to validate this error — it's processing transactions normally now. This looks like a transient environment issue on the machine it ran on rather than a bug in the automation itself, so we'll keep monitoring the next runs across the different robot machines before closing this out."
2. Follow-up: "Adding context to my last comment: before re-running in Production, we also validated the same flow via a Studio debug session in Staging, where the Quote PDF download completed successfully end-to-end. That, plus the clean Production re-run, points to a transient environment issue rather than a code defect."

Ticket is NOT closed — status is "monitor next executions across robot machines" before deciding to close or revisit the Downloads-folder fallback.

**Branch housekeeping done this session (not ticket-related):** stashed 3 uncommitted, out-of-scope files that were sitting on the branch before this session started — `git stash` message "BT-75058 setaside: census salary rounding + waived deps removal (ProcessTransaction.xaml) + local Z:/Y: drive paths (config.json) + Studio cosmetic noise (Main.xaml) - not in scope for this ticket". That stash still needs a decision later (drop it, or it belongs to a different ticket/branch — the salary-rounding/waived-deps code referenced "Bri Boyer, 08/03" approval, predates this ticket). Also created `.claude/rules/project-context.md` + `AGENTS.md` for this project via the discovery agent (first time either existed) — flagged that the project's own hand-maintained `CLAUDE.md` describes a numbered "Step N" / "DEBUG GATE" MessageBox pattern that no longer exists in the current `ProcessTransaction.xaml` (now uses a `debugMode` config flag instead) — that CLAUDE.md section is stale.

## New lead (2026-08-20): error on "Group Details" screen right after typing the SIC code

User reported a live-debug error on the Group Details screen that surfaces right after the SIC code is typed/verified. Traced the flow in the same file (`EnterCompanyInfo.xaml`) that owns the Quote PDF bug — not confirmed yet whether it's the same root cause or a separate one, but both live in this file so worth checking together.

**Flow after SIC verification** (`EnterCompanyInfo.xaml`, ~lines 523-830):
1. `While_SelectSICVerified` loop confirms the SIC code (throws `BusinessRuleException` via `Throw_SICNotVerified` at line 681 if not verified after 4 attempts).
2. Checks `Medical` + `Fully Insured`, unchecks `Level Funded` (`NCheck_1`/`NCheck_3`/`NCheck_4`) on the `start-quote` screen.
3. `Click_13` "Click 'Group Details'" (line 735) — selector `aaname='Group Detailschevron_right'`, `TimeoutMS=30000` — navigates to the Group Details screen.
4. `Sequence_39` "Enter Group Details" (line 751): `TypeInto_TAE` "Total Applying Employees" (`DelayBefore=1000`), `TypeInto_TWE` "Total Waiving Employees", then inside `NApplicationCard_3` scoped to `group-details`: `NTypeInto_1` "Tax ID", `TypeInto_20` "Admin First Name", etc.

**Most fragile candidates for the reported error** (not yet confirmed against the actual error message — user is about to report it):
- `Click_13` — 30s timeout waiting for the "Group Details" button to become clickable; `ContinueOnError=False`.
- `TypeInto_TAE` — first interaction on the new screen, only `DelayBefore=1000`; if the screen hasn't finished rendering/loading after the SIC selection + checkbox clicks, this is the first thing that would fail.

**Status:** waiting on the user to paste the exact error message/screenshot from the debug run to pinpoint which activity actually threw.

## Update 2026-08-21 — overnight Prod run confirms zero Quote PDF recurrences

Checked job `f1197ba1-df41-43f5-bb3e-1b228e1b1184` (folder `Benefits`, machine `USCOL1-ROBOT-6`) the user left running overnight: ran 2026-08-21 00:47–03:21 (2h34min), `State: Successful`. Queue `UnitedHealthCare_GroupSubmissions_NewPlans_SAMx` (key `c6540bc9-85cc-4ba1-b023-532ed5a4b7a4`, folder `Benefits` — NOT `Benefits/CarrierAutomation`, matches the pattern in [[reference_orchestrator_folder_vs_repo_path]]) processed 13 items in that window: 7 Successful + 6 Failed. **Zero of the 6 failures were the "Unable to download Quote PDF"/Save As error** — all were other already-known-out-of-scope types (selector-not-found on unrelated fields, participation failure, census manual-review, employee-enrollment warning, ATNE/FTE minimum x2, "Order is no longer in Automation Queue"). Strong supporting evidence for the transient-environment conclusion.

**Caveat found while checking:** queue is NOT fully zeroed despite how it looked in the Orchestrator UI — 1 New item (arrived 13:03 same day, unrelated/fresh) + 5 InProgress items that look stuck/abandoned: 2 have `StartProcessing` inside the overnight job's window (00:33, 01:00) that never resolved to Successful/Failed, and 3 predate the overnight job entirely (`StartProcessing` 18:53/19:01/19:38 on 2026-08-20). These 5 are likely orphaned from earlier/other job runs, not connected to last night's validation run — worth a separate look (possible stuck-session/abandoned-item cleanup) but not evidence against the fix conclusion.

**Full job-log walkthrough (start to end), exported via `uip or jobs logs --export` (comes back as a zip, not raw CSV — unzip first):** confirmed the same "zero Quote PDF recurrences" conclusion at the log level, not just queue-item level. Timeline of the 6 in-window failures: 00:50 ATNE/FTE business rule, 01:54 employee-enrollment warnings, 02:29 "Small Group Quoting & Renewals" selector not found, 02:42 census manual-review alert, 03:08 ParticipationException, 03:20 "Agent name" selector not found. Job ended cleanly via "No Transaction Data" (queue drained), not a crash. **New tangential finding (not this ticket's bug, flagged for awareness only):** recurring transient "Login page not available" (5x, all self-recovered on retry) and repeated navigation-selector misses ("Small Group Quoting & Renewals" 3x, "Agent name" 2x, "Total Applying Employees" 1x) — 3 of the 6 final failures were selector-not-found on post-login navigation, not business-rule errors. Worth a separate look if this pattern keeps recurring, but out of scope for BT-75058.

## Closed 2026-08-21

Posted closing comment on BT-75058 (Jira comment id 4391315) summarizing the overnight Prod run (job `f1197ba1-df41-43f5-bb3e-1b228e1b1184`, 13 transactions, zero Quote PDF recurrences) and stating the bot has stabilized on this specific error; noted we'll keep monitoring and will reopen/file new if it resurfaces. User transitioned the ticket to **Done** manually in the Jira UI (the `uip`-driven transition via MCP hit two required screen fields — "Complexity & Time Spent" and "BizTech Issue Category" — that aren't exposed through the API tools available, so the transition was done by hand instead). **Ticket is now closed.** Per user instruction, monitoring continues informally (no formal recurring check scheduled) — if the Quote PDF error resurfaces, treat as new/reopened rather than assuming this closure was wrong.
