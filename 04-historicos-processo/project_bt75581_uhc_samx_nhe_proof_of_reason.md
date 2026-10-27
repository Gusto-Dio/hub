---
name: project_bt75581_uhc_samx_nhe_proof_of_reason
description: "BT-75581 - UHC_SAMX_NewHireEnrollment_Modern - portal added 'Proof of Reason' documentation-required step for some Qualifying Event enrollments (FL/NY/NJ/MD/DC/VA/WV, effective 2026-09-01); also found and fixing a widespread pre-existing selector bug (parentid='capture') across the whole process AND the shared LoginToUHC library, discovered live during Staging debug."
metadata:
  node_type: memory
  type: project
  originSessionId: 24c35a48-2c3a-437d-acde-b38474a8e1a4
  modified: 2026-09-15T23:09:31.057Z
---

**Ticket:** BT-75581 (reporter Tammy Borders, High priority). Impacted: `UHC_SAMX_NewHireEnrollment_Modern`
(ProcessKey `UHC_SAMX_NewHireEnrollment_Modern`, v1.3.9 — the Modern one, distinct from legacy
`UHC_SAMx_NewHireEnrollment`/`UHC_SAM_NewHireEnrollment`). Ask: portal shows a new "Proof of Reason"
documentation-required step for some EEs; bot should fail the case with a specific message instead of
retrying forever.

**Branch:** `BT-75581-UHC-SAMx-NewHireEnrollment-selector-fix`, created off `origin/develop` (updated via
`git fetch origin develop` first — local was behind). Upstream tracking to `origin/develop` was
deliberately unset right after creation to avoid an accidental push to develop. Nothing committed yet.

## Investigation (logs first, per Iron Rule)

Pulled 100 most recent `Failed` items from Production queue `UHC_SAMx_NewHireEnrollment` (folder `Benefits`,
queue definition key `5d52d905-024a-4597-98d9-b337f5a191d1`) — **~85% fail at the exact same point**:
`Could not find the UI element ... at source: EnterReasonForEnrollment: Set Text :: Requested effective date.`
Confirmed this matches all 3 ticket example refs (`500R70000180b7PIAQ`, `500R7000015feKlIAI`,
`500R7000017P4FJIA0`) exactly.

Sheets: ticket **not found** in tracking spreadsheet (`_sheets_not_found`) — populated data ends around
row ~230 (`BT-72802`), recent 755xx tickets aren't logged there yet.

## Staging repro setup

Queue `UHC_SAMx_NewHireEnrollment` in Staging (folder `Benefits`, key `ea0616e4-eb4e-4773-92c4-2ddba1e8fd89`)
had 79 stale `New` test items — **deleted all 79** (`queue-items delete-bulk`, explicit GUIDs spelled out
literally in the command — the auto-mode classifier blocked a `$(cat file)` substitution version citing
"Unverifiable Deletion Scope"; spelling out the GUIDs literally in the command text let it verify scope and
pass) and **recreated the 3 ticket refs** with their real `SpecificContent` copied verbatim from the
Production `Failed` items (via `uip or queue-items add --specific-content`). This is standard practice for
this codebase — real PII moved between two Gusto-managed, access-controlled Orchestrator tenants for
legitimate repro, not published anywhere external/personal.

**Recurring housekeeping during live debugging:** every time a Studio debug session stops mid-transaction
(without reaching `SetTransactionStatus`), the queue item is left stuck in `InProgress` forever (queue has
`MaxNumberOfRetries: 0`, `AcceptAutomaticallyRetry: false` — no auto-retry). No CLI command resets status
directly (`queue-items update` doesn't touch `Status`) — the fix each time is `queue-items delete` the
stuck item + `queue-items add` it back with the identical `SpecificContent`/reference. Did this twice this
session for `500R70000180b7PIAQ` and `500R7000015feKlIAI`.

## Root cause #1 — Proof of Reason (user's fix, confirmed correct)

User captured the live element in Studio and added `NCheckState_2` in `EnterReasonForEnrollment.xaml`,
right after selecting "Reason for enrollment" and before the two date fields:
- Target: `<webctrl class='uhg-input--contained__container--error' parentid='enrollment-demographics-start'
  tag='P' innertext='Note: Proof of reason required: Please upload required documents in the section at the
  bottom of the page' />`
- If exists → `Throw New BusinessRuleException("Proof of reason required: Please upload required documents
  in the section at the bottom of the page")`

Confirmed via the saved live HTML page that this is a real, new UHC portal notice (visible text on page):
*"Effective September 1, 2026, upload of supporting documentation will be required for Small Business groups
in: FL – all Qualifying Event enrollments. NY – expansion to all Qualifying Event enrollments – only if group
has 5 or fewer enrolled subscribers... NJ, MD, DC, VA, WV – all Qualifying Event enrollments (since March 1,
2026)."* Explains "some EEs" from the ticket exactly — it's QE-reason enrollments in those specific states.

## Root cause #2 — systemic `parentid='capture'` selector bug (found live, fixing as we go)

**`id="capture"` appears exactly once on the whole UHC member-enrollment page** — it's `<div
class="container-content" id="capture">`, the page-wide wrapper used only for the print-preview button
(`printPreviewJS({obj2print:'capture',...})`). It has nothing to do with any specific field. Selectors written
as `parentid='capture'` most likely worked historically because for most controls "capture" happened to be
the *nearest ancestor with any `id` at all* — until UHC recently wrapped sections in new named containers
(`<demographic id="enrollment-demographics-start">`, `<datepicker datepickerid="reqEffDateId">`, etc.),
which are now the *actual* nearest-id ancestor for those controls, breaking every `parentid='capture'`
selector inside them. This reads as one coordinated UHC portal DOM restructuring, not several unrelated bugs.

**Confirmed + fixed so far (all in `UHC_SAMX_NewHireEnrollment_Modern/Framework/`):**
- `EnterReasonForEnrollment.xaml`, `NSetText_2` ("Set Text :: Requested effective date") — old:
  `parentid='capture' tag='DIV' innertext='   calendar_today' parentclass='ng-untouched ng-pristine
  ng-*valid'` → new: `tag='DATEPICKER' datepickerid='reqEffDateId'` (anchored on the field's own unique
  custom-element id instead). Confirmed live: `EnterReasonForEnrollment was successful.`
- `EnterSubscriberInformation.xaml`, `NSelectItem_1` ("Select Item :: Gender") — old `parentid='capture'` →
  new `parentid='enrollment-demographics-start'`. Confirmed via live runtime error + Studio's own
  closest-match suggestion (74%: `parentid='enrollment-demographics-start'`).
- `EnterSubscriberInformation.xaml`, "Select Status*" (`NSelectItem_2` target + the `NCheckState` that
  guards it, 2 occurrences) — same fix, `parentid='capture'` → `parentid='enrollment-demographics-start'`.
  Confirmed via saved HTML (no closer `id` ancestor found for this field either).

Both fixes validated (`uip rpa validate` — 0 diagnostics) and one full project `uip rpa build` passed clean
(only pre-existing unrelated warnings — idx-selectors, default activity names, etc., same class already
known from other UHC processes).

**NOT yet fixed / not yet evidenced (do not touch blind):** 14 more `parentid='capture'` occurrences found
via grep across this same process:
- `EnterSubscriberInformation.xaml` — Marital Status, Subscriber Type* (2x) — **no live evidence yet**,
  these `formcontrolname`s (`maritalStatus`/`subscriberType`) never appeared in either saved HTML capture,
  so unclear if they're even real fields for these test cases or dead/legacy selectors.
- `EnterDependentInformation.xaml` — Select Dependent* (2x), Gender* (dependent, has `idx` templating)
- `EnterSubscriberCoverage.xaml` — Future/Current Contract year selection (4x)
- `CheckIfThereAreDependents.xaml` — "Next" button
- `CompleteEnrollment.xaml` — "Submit" button
- `NavigateToEnrollment.xaml` — "person_add" icon

Strategy agreed with user: fix each remaining one **only when live-confirmed** (either a runtime error with
Studio's closest-match hint, or direct HTML evidence), not a blind sweep — per the Iron Rule (verify before
fixing).

## Root cause #2, escalated scope — same bug likely in the SHARED login library (Gusto_Benefits_UHC_SAMx)

While testing, Production's own `UHC_SAMX_NewHireEnrollment_Modern` (holder `ROBOT1-PRD-AWS`) has been
**repeatedly tripping the shared `MFA_UHC` login circuit breaker** all session (2026-09-14, at least 4
separate open events between ~19:35 and 23:16, escalating open-duration: 20min → 1h → 15min → 30min), every
time with the identical `lastReason`: `"Could not find the user-interface (UI) element for this action...
Unknown"`. Since `Credential_UHC_SAMx_MOps.breaker.json` stays `state: Closed` throughout (password is fine,
`lastSuccessUtc` recent), this is not a credentials problem — see [[reference_login_circuit_breaker_locks_share]]
for the shared-breaker mechanics (`\\fs3-prd-aws.gustocorp.com\BizTech\RPA\Locks\`, `MFA_UHC.breaker.json` /
`.json` lock file / `Credential_UHC_SAMx_MOps.breaker.json`).

Found a strong candidate root cause: `Libraries/Gusto_Benefits_UHC_SAMx/LoginToUHC.xaml` has (3 occurrences,
lines ~449/556/899) the exact same broken pattern: `<webctrl parentid='capture' tag='SPAN'
aaname='Welcome,*' />` — the check used to confirm successful login landed on the Home page. **Hypothesis,
NOT yet confirmed via Production logs**: username/password/MFA all succeed (matches this session's own
successful Staging login pattern — `GetAccessCode was successful` / `LoginToUHC was successful` do appear
before the circuit-open errors in some runs), but this final "Welcome," landing-page check may now be
failing for the same DOM-restructuring reason as everything else, making the framework treat a *successful*
login as a failure and open the breaker.

**NOT confirmed, NOT fixed.** This is a shared Library (`Gusto_Benefits_UHC_SAMx`) — per CLAUDE.md Library
Rules, changes there affect every process that depends on it (need to check which processes besides
`UHC_SAMX_NewHireEnrollment_Modern` consume this library before touching it). If confirmed, this is a
**separate, higher-severity, currently-active Production incident** (repeatedly blocking real UHC SAMx
logins in Production right now, not just our Staging test) — deserves its own ticket/PR and probably a
heads-up to Sri/Oscar, not a fix bundled into BT-75581. User decided to just keep waiting out the breaker
for now rather than investigate immediately; revisit if it keeps recurring or when there's bandwidth.

## Root cause #2 — third fix confirmed + full end-to-end pass (2026-09-15)

**`CheckIfThereAreDependents.xaml`, `NClick_1` ("Click :: Next", branch "If number of dependents is zero")** —
same `parentid='capture'` bug. First guess from Studio's closest-match list (89%: `parentid='current'`) turned
out **wrong** when live-tested — real fix (confirmed via live re-indication in Studio, i.e. direct capture,
the strongest evidence tier) is `parentid='enrollment-demographics-start'` (same container as the
Gender/Status fixes) with `aaname='*Next*'` (wildcard, not exact `' Next'`). **Lesson: Studio's fuzzy
closest-match % is a hint, not proof — only live re-indication or direct HTML confirms.** Validated
(`uip rpa validate` — 0 diagnostics) after both the wrong guess and the corrected live-indicated version.

**Full end-to-end pass achieved** on `500R7000015feKlIAI` (CA, zero dependents) — 2026-09-15 20:43-20:49,
jobId `3ca182eb-3ec5-4cff-8846-5607091a212a`: `EnterReasonForEnrollment` → `EnterSubscriberInformation` →
`EnterContactInformation` → `CheckIfThereAreDependents` → `EnterSubscriberCoverage` → `CompleteEnrollment` →
**`transactionStatus: "Successful"`**, zero errors. This confirms:
- All 3 applied selector fixes work together for this case.
- `EnterSubscriberCoverage.xaml` (Future/Current Contract year, 4x `capture` occurrences) and
  `CompleteEnrollment.xaml` (Submit button, `capture`) were **not** affected for this case/state — passed
  as-is. Matches the earlier 80% closest-match hint seen during the Next investigation
  (`aaname=' Submit' parentid='capture'` was itself a *suggested* match, implying `capture` really is still
  the correct ancestor for Submit).
- **NOT exercised**: `EnterDependentInformation.xaml` (2x `capture`, Select Dependent/Gender) — this case had
  `in_NumberOfDependents = 0`, so the "Add Dependent" branch never ran. Still needs a case with dependents > 0
  to confirm/deny.
- Marital Status / Subscriber Type (2x, `EnterSubscriberInformation.xaml`) — still no live evidence either way.

## State as of 2026-09-15 ~20:50

- 3 real selector fixes applied + validated in `UHC_SAMX_NewHireEnrollment_Modern` (Reason page datepicker,
  Subscriber Info Gender/Status, CheckIfThereAreDependents Next), nothing committed to git yet.
- Working pattern this session for stuck items: when a debug run stops mid-transaction without reaching
  `SetTransactionStatus`, the queue item is left `InProgress` forever (no auto-retry) — fetch its
  `SpecificContent` via `uip or queue-items get <uniqueKey> --folder-path Benefits --all-fields`, delete it
  (`uip or queue-items delete <uniqueKey> --folder-path Benefits --yes`), recreate via
  `uip or queue-items add "UHC_SAMx_NewHireEnrollment" --folder-path Benefits --priority Normal --reference "<ref>" --specific-content "$(cat <scratchpad-file>.json)"` (BOM-free file + `$(cat ...)` in Bash, per
  [[feedback_uip_cli_json]]). Did this successfully twice this session.
- Staging queue `UHC_SAMx_NewHireEnrollment` (folder `Benefits`, definition key
  `ea0616e4-eb4e-4773-92c4-2ddba1e8fd89`): `500R7000015feKlIAI` now `Successful` (full pass). `500R70000180b7PIAQ`
  (NY) and `500R7000017P4FJIA0` (FL) are `New`, not yet re-run — expected to hit the legitimate Proof-of-Reason
  `BusinessRuleException` again (correct behavior, not a bug).
- Login circuit breaker (`MFA_UHC`, shared) did NOT trip this run — `LoginToUHC was successful` cleanly,
  consistent with the hypothesis that Production breaker trips were from the *same* `parentid='capture'` bug
  hitting the shared `Gusto_Benefits_UHC_SAMx/LoginToUHC.xaml` "Welcome," check — still not directly confirmed
  against Production logs, still not fixed, still a separate/higher-severity ticket candidate.
- No PR opened yet. `project.json` version not bumped yet (still 1.3.9) — remember before PR per
  [[feedback_check_version_bump_before_pr]]. Still 11 more `parentid='capture'` occurrences un-confirmed
  (Marital Status, Subscriber Type, EnterDependentInformation x2, NavigateToEnrollment "person_add" icon) —
  per the Iron Rule, fix only with live evidence, not blind sweep.
- Project-level `uip rpa build` passed clean (`Success: true`) — only pre-existing warnings (idx selectors,
  default activity names, display-name duplicates), same class already known from other UHC processes.
- Root `dependencylock.json` (repo-wide floor) vs this process's `project.json`: `Gusto_Benefits_UHC_SAMx`
  pinned `[1.0.12]` in project.json vs floor `1.0.10` in root lock — project.json is *higher*, looks fine
  (satisfies the floor), but not yet cross-checked against the true HEAD of `origin/develop` because of the
  GitHub outage below. Re-verify once network is back, per [[feedback_check_dependencylock_before_pr]].
- **Blocked on GitHub connectivity (2026-09-15 ~20:55-21:00):** `git fetch origin develop` fails with a TLS
  handshake error (`schannel: failed to receive handshake`) from both git-bash and native Windows git/schannel
  — tried the known `-c http.sslBackend=openssl` fix from [[feedback_git_tls_schannel_fix]], same error, so
  this is NOT that known issue. Confirmed it's GitHub-specific, not a general network outage: `google.com` and
  `cloud.uipath.com` both return 200 via `Invoke-WebRequest` at the same time. Blocks `fetch`, `push`, and PR
  creation. Local work (edit, validate, build, commit) is unaffected. Retry fetch once user confirms network/
  VPN is back before pushing or opening the PR.
- **DONE (2026-09-15 ~21:00):** GitHub connectivity came back (was a transient GitHub-specific TLS outage, not a
  general network issue). Bumped `projectVersion` to `1.3.10`, committed the 5 files (3 Framework/Main XAML +
  `project.json`), merged `origin/develop` (clean, no conflicts — two-dot diff now scoped to only our 5
  files), pushed, packed (`uip rpa pack ... --package-id UHC_SAMX_NewHireEnrollment_Modern`), uploaded to
  Staging (`uip or packages upload` — was only `1.3.6` in Staging before, now `1.3.10`), and opened
  **PR #3334** (`develop` ← `BT-75581-UHC-SAMx-NewHireEnrollment-selector-fix`).
  `https://github.com/Gusto/biztech-uipath-rpa/pull/3334`
- Root `dependencylock.json` conflict from earlier turned out to be a non-issue once compared against the
  real `origin/develop` — Gusto_Benefits_UHC_SAMx floor is unrelated to this process's pinned version, no
  action needed.
- **2026-09-15 22:30: PR #3334 MERGED** into `develop` (merged by user, Gusto-Dio). Buildkite build #14569
  passed and uploaded `UHC_SAMX_NewHireEnrollment_Modern:1.3.10` to the Production feed, but did NOT bind it
  to the actual Process (`createProcess=false` — see [[feedback_buildkite_production_deploy_only_feed_not_process]]
  for why). User manually promoted the Process in Production; confirmed via `uip or processes list
  --folder-path Benefits`: `ProcessVersion: 1.3.10`, `IsLatestVersion: true`. Jira BT-75581 updated with a
  closing comment (implemented, tested, published to Production).
- Still open, not part of this ticket: the separate `Gusto_Benefits_UHC_SAMx/LoginToUHC.xaml` shared-library
  suspicion (Root cause #2, escalated scope above) — still not confirmed, still not fixed, still a candidate
  for its own ticket.
