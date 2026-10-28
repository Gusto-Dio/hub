---
name: project_bt75495_kaiser_delegate_account_login
description: "BT-75495 - Kaiser RPA Delegate Account credentials + delegate-account book-of-business switch across 6 Kaiser processes. ALL 6 processes confirmed end-to-end in Staging; all 7 PRs open (#3310-#3317) awaiting Oscar's approval. URGENT: user already swapped Credential_Kaiser_CA in Prod BEFORE code deployed -- 5 in-scope Prod triggers disabled as mitigation, must re-enable after merge+deploy; Kaiser_Reconciliation + legacy Kaiser_GroupSubmissions_MemberLevel still at risk (out of scope, no fix). As of 2026-09-11."
metadata:
  node_type: memory
  type: project
  originSessionId: 5a5b1007-4059-4b74-9ec8-52734257d1e6
  modified: 2026-09-11T19:39:28.938Z
---

**Ticket:** BT-75495 (Tammy Borders, priority Low). Kaiser RPA Delegate Accounts were created; bots need the new credentials AND need to navigate through the delegate-account UI (portal doesn't land on the full book of business under the robot's own account) to reach the group/member the same as before.

**6 impacted processes** (from ticket): `Advising_Kaiser_PacketCollection`, `Kaiser_CA_MemberUpdates`, `Kaiser_CA_NewHireEnrollment`, `Kaiser_CA_Terminations`, `Kaiser_GroupSubmissions_MemberLevel_Modern`, `Kaiser_GroupSubmissions_NewPlan`.

## Architecture discovery (the trap)

Two *different* `LoginToKaiser` implementations exist, both invoked via the same `gkg:` XAML prefix — name similarity does not mean same code, always check the actual `xmlns:gkg="clr-namespace:...;assembly=..."` declaration in the consuming file before editing:
- `Libraries/Gusto_Benefits_Kaiser_CA` (standalone lib, modern `uix:N*` activities) — used by **only** `Kaiser_GroupSubmissions_MemberLevel_Modern`.
- `Libraries/Gusto_Benefits/Kaiser_CA/Generic/LoginToKaiser.xaml` (inside the `Gusto_Benefits` mega-lib, **classic** `ui:Click`/`ui:TypeInto`/`ui:UiElementExists` activities) — used by the other 5 processes, including `Kaiser_CA_MemberUpdates`.

First pass in this session wrongly fixed only the standalone lib (see [[feedback_verify_process_guid_before_editing_sibling]] — same name-similarity trap, different mechanism/library instead of process). Caught it when `Kaiser_CA_MemberUpdates` tested with the fix and showed zero effect — traced `gkg:LoginToKaiser`'s real `xmlns` in `Framework/InitEnvironment.xaml` and found the mega-lib. Both libs ended up needing the fix (they serve different real consumers), so nothing was wasted, but it cost a round of confusion.

## What was built (in `Libraries/Gusto_Benefits/Kaiser_CA/Generic/` and mirrored in `Gusto_Benefits_Kaiser_CA`)

1. **"Get Passcode" MFA method-selection screen fix.** Kaiser now sometimes (confirmed intermittent via live testing — not every login) shows a screen asking Email vs Mobile for the MFA code, between Sign In and the passcode-entry field. Neither `LoginToKaiser.xaml` variant handled it — the bot would sit waiting for the passcode field forever and time out as "Login failed". Fix: an existence-check (`Exists="[getPasscodeMethodPageShown]"`, 5s timeout) right after Sign In, wrapped `If` that clicks "Email" then "Continue" only when the screen is actually there. Confirmed both branches live: screen present → clicks fire + logs fire; screen absent → skips cleanly, falls through to the pre-existing passcode flow with zero regression.
2. **New `SwitchToDelegatedAccount.xaml`** (in the mega-lib's `Kaiser_CA/Generic/`, invoked as `gkg:SwitchToDelegatedAccount` right after `gkg:LoginToKaiser`): navigates `.../broker/account-delegation` → clicks "View {delegate}'s account" → navigates `.../broker/client-overview` → clicks "Small Business". After this, existing per-process search/edit logic (`SearchForGroup`/`SearchForEmployee`/`EditEmployee` etc.) resumes unchanged — ticket's step 6 ("search group number") already existed and needed no mapping.
3. **Delegate name not hardcoded.** Created Orchestrator asset `Kaiser_DelegateAccountName` (Text, Global scope, **Staging** tenant, shared with folders `Benefits` + `Benefits/CarrierAutomation`, same pattern as `Credential_Kaiser_CA`). Fetched via `ui:GetRobotAsset` — **must use child-element binding** (`<ui:GetRobotAsset.Value><OutArgument x:TypeArguments="x:String">[var]</OutArgument></ui:GetRobotAsset.Value>`), the attribute form (`Value="[var]"`) throws "Set property ... threw an exception" at load time. Selector uses the project's existing dynamic-selector convention (`aaname='*{delegateAccountName}*'`, single braces, see CLAUDE.md Selector Guidelines) — confirmed this resolves correctly at runtime for modern `uix:TargetAnchorable` selectors too, not just classic ones. Per user's explicit ask: the delegate's name is **never written to logs** — log message says only "obtained from asset and selected", no name string.
4. **Package upgrade required.** `UiPath.UIAutomation.Activities` 24.10.11 → 26.10.3 in the standalone `Gusto_Benefits_Kaiser_CA` lib — the captured selectors used the newer `Version="V6"` target schema, which the old package version rejects ("Failed to create a 'Version' from the text 'V6'"). Required explicit user consent per the uipath-rpa skill's package-upgrade rule; got it.
5. **Pre-existing SecureString bug fixed as a side effect.** The above upgrade surfaced two brand-new-to-us analyzer errors (`ST-SEC-008`/`ST-SEC-009`) in `Gusto_Benefits_Kaiser_CA/GetAccessCode.xaml`: `Get IMAP Mail Messages` was extracting the SecureString password to plaintext via `NetworkCredential`, AND using the SecureString variable outside its creation scope (declared in the outer Sequence, used inside a `RetryScope.ActivityBody`'s `ActivityAction` delegate). Fixed by switching to the activity's native `SecurePassword` property and moving the `GetRobotCredential` call inside the same `ActivityAction`/Sequence where it's consumed (SecureString must be created and used in the same delegate scope). Not otherwise related to this ticket, but blocked the build once the package moved.

## Infra/process lessons (see also standalone feedback memories)

- Buildkite (`.buildkite/README.md`) **only auto-deploys to Production**, on merge to `develop`. There is no automated Staging publish, ever — see [[feedback_buildkite_production_only_autodeploy]].
- `uip or packages upload` (Process/Automation package feed) ≠ `uip or libraries upload` (tenant Library feed used for design-time dependency restore). Used the wrong one first, `uip rpa packages install` kept failing to see the new type — see [[feedback_uip_libraries_vs_packages_upload]].
- Local NuGet cache collisions when re-packing the same version number with different content during iterative local testing — see [[feedback_local_nuget_cache_version_collision]].
- `Gusto_Benefits` mega-lib has **317 pre-existing analyzer errors** across unrelated carriers (BCBS TX, other Kaiser flows, etc.) — `uip rpa build`/`pack` need `--skip-analyze` for ANY work touching this lib. This is pre-existing, tolerated by the team already (not something to fix here). Same story, smaller scale, for `Kaiser_CA_MemberUpdates` itself: one pre-existing `UI-DBP-006` (Top level selector used outside scoped containers) in `TakeFullPageScreenshot.xaml`, confirmed unrelated — will likely surface on this PR's real Buildkite run too, same as [[project_bt75501_uhc_samx_memberupdates_name_already_updated]]'s precedent.

## Branch/PR strategy (user's explicit ask)

Split into separate PRs, opened in dependency order, each commented on the Jira ticket as it opens:
1. **Library PR first** — `BT-75495-Kaiser-Library-DelegateAccount-fix` → **PR #3303** (OPEN, not yet reviewed/merged as of session end): both `LoginToKaiser.xaml` fixes + new `SwitchToDelegatedAccount.xaml` + the SecureString fix + version bumps (`Gusto_Benefits` 1.559.17→**1.559.20**, `Gusto_Benefits_Kaiser_CA` 1.2.0→**1.2.1**). Jira comment posted.
2. **Then the consuming process PR** (`Kaiser_CA_MemberUpdates`, branch `BT-75495-Kaiser-Login-delegate-account-navigation`) — not opened yet.
3. **Then the remaining 4 processes**, one at a time, each tested before moving to the next, each commented on Jira as it opens.

**Git technique used to split one working branch into two clean PRs** (useful pattern, reusable): since neither branch had any commits yet (both still at develop's HEAD, all changes uncommitted in the working tree), `git checkout -b <new-branch>` from that position, then `git add`+`git commit` **only** the subset of files for PR #1 on the new branch (the rest stays uncommitted). Switching back to the original branch name naturally reverts the now-committed subset to the original branch's HEAD (pre-fix) while preserving the still-uncommitted subset untouched — clean separation with zero stashing/cherry-picking.

Also had to `git merge origin/develop` into the new library branch before opening PR #3303, because BT-75501's PR (#3302, unrelated ticket) merged into `develop` mid-session and made the two-dot Buildkite diff show unrelated `UHC_SAMx_MemberUpdates` noise — standard [[feedback_check_dependency_before_pr]]-style hygiene.

## Testing done

3 consecutive full end-to-end Staging runs of `Kaiser_CA_MemberUpdates`, replaying a real Prod-sourced transaction (Salesforce case `500R70000187o9WIAQ`, group `732813`, home_address update for a real employee, added to Staging queue with `--specific-content` from a real Successful Prod queue item's SpecificContent). All three: MFA/Get-Passcode handled correctly (both with and without the screen appearing across runs) → delegate switch via asset → Small Business → `SearchForGroup` → `SearchForEmployee` → `EditEmployee` → **Transaction Ended: Successful**. First two runs used a **locally-packed** test version of the library (never published anywhere real); the third run (and the queued-but-unconfirmed 4th) used the **real, published-to-Staging-Orchestrator-feed** `Gusto_Benefits 1.559.20`.

## RESOLVED 2026-09-10 ~21:42 — Kaiser_CA_Terminations confirmed end-to-end Successful in Staging

Two separate real bugs, both found via live debugging on Terminations (not visible from static code review alone):

1. **Delegate-row click selector** (`SwitchToDelegatedAccount.xaml`, "Click 'View delegated account'"): `FuzzySelector` (even with `tableCol`) is fundamentally unreliable against this Angular account-delegation table — confirmed by 3 failures on Terminations despite passing once on `Kaiser_CA_MemberUpdates` (lucky, not fixed). Real fix: switch to `SearchSteps="Selector"` (strict engine) with the **exact** selector the user live-captured — `FullSelectorArgument` using `tableRow='2'` + `colName=' View Accounts '` + `tableCol='4'`, plus `InteractionMode="DebuggerApi"`. Landed in library `1.559.23` (PR #3311, not yet merged as of this note) — see [[feedback_angular_table_colname_rowname_unreliable]] (needs updating: FuzzySelector itself is unreliable here regardless of attributes, not just colName/rowName specifically).
2. **Missing pre-navigation before SearchForGroup**: `Kaiser_CA_MemberUpdates`'s `Framework/Process.xaml` has an `NApplicationCard` (attaches to `business.kaiserpermanente.org*`) wrapping an `NGoToUrl` to `https://business.kaiserpermanente.org/managemembers#/groups`, run at the very start of transaction processing, BEFORE ever invoking SearchForGroup. This federates the delegate session into the legacy EBSS system (`account.kp.org`) correctly. `Kaiser_CA_Terminations` never had this step — its `SearchForGroup` call (`gkg:SearchForGroup`, compiled library activity — note the local `ProcessLayer/SearchForGroup.xaml` InvokeWorkflowFile call sits dead inside a `CommentOut`, a trap almost identical to [[feedback_verify_process_guid_before_editing_sibling]]) tried to reach Manage Members cold via `account.kp.org/EBSS/...` and never got the right redirect, staying stuck on "Client Overview". Fix: added the identical `NApplicationCard`+`NGoToUrl` block to `Kaiser_CA_Terminations/Framework/Process.xaml` right before `gkg:SearchForGroup`.

**Process-level lesson:** comparing `InitEnvironment.xaml` (init/login) is not enough to rule out "missing step" — the actual per-transaction navigation lives in `Process.xaml`, and a workflow file can be present on disk (`ProcessLayer/SearchForGroup.xaml`) but be completely dead (wrapped in `CommentOut`) while a same-named *compiled library activity* (`gkg:SearchForGroup`) is what actually runs. Always check what's ACTUALLY invoked (not commented out) before diffing "the same file" across two processes.

**Git process note:** while testing, accidentally committed the `Process.xaml` fix on the wrong branch (`BT-75495-Kaiser-Login-delegate-account-navigation`, the MemberUpdates PR branch) because a `git checkout <branch>` earlier to test MemberUpdates was never switched back before editing. Recovered cleanly via `git reset HEAD~1` (soft, kept working tree) → `git stash` → `git checkout <correct-branch>` → `git stash pop` → commit. Lesson: after switching branches to run/test something, always `git branch --show-current` before the next edit, don't assume you're still on the branch you meant to be on.

## Where we stopped / what's left (pick up here) — updated 2026-09-10 ~20:20

1. **PR #3303 (libs, MFA + initial delegate-switch) MERGED** into develop 2026-09-10 15:12 UTC.
2. **PR #3307 (`Kaiser_CA_MemberUpdates`) MERGED** into develop 2026-09-10 20:19 UTC.
3. **Real bug found + fixed while mapping `Kaiser_CA_Terminations`** (see [[feedback_angular_table_colname_rowname_unreliable]]): `SwitchToDelegatedAccount.xaml`'s "Click 'View delegated account'" failed live 2x with "Could not find the UI element" even though visible on screen. Root cause: Kaiser's account-delegation table is Angular with comment-node placeholders between cells, breaking `colName`/`rowName` (name-based) table addressing. Fixed via **two follow-up library commits, both in PR #3309 (MERGED 2026-09-10 20:12 UTC)**:
   - `1.559.21`: selector `colName='View Accounts' rowName='*{delegateAccountName}*'` → dynamic `aaname` + `tableCol='4'` (column-index addressing, confirmed via live re-capture)
   - `1.559.22`: selector alone wasn't enough — click still didn't reliably register; added `InteractionMode="DebuggerApi"` (CDP-level dispatch) to the same `NClick`, confirmed working
   - `Kaiser_CA_MemberUpdates` (which had appeared to work before on `1.559.20`) was bumped to `1.559.22` and **re-confirmed end-to-end** (login → MFA → delegate switch → SearchForGroup → SearchForEmployee → EditEmployee → Transaction Ended: Successful) — meaning the old colName/rowName selector was flaky/lucky even in earlier "successful" runs, not actually reliable.
4. **`Kaiser_CA_Terminations`**: branch `BT-75495-Kaiser-CA-Terminations-delegate-account-navigation`, NOT pushed/PR'd yet. Locally has: delegate-switch wiring + removal of the now-redundant `gkg:NavigateToBookOfBusiness` call (see [[feedback_navigatetobookofbusiness_redundant_after_delegate_switch]]) + bump to `Gusto_Benefits 1.559.22`. **Needs retesting** with the `1.559.22` fix before push/PR — last live test (on `1.559.21`, pre-DebuggerApi) got past the delegate switch but failed in `SearchForGroup` (same "Could not find the UI element" pattern against `title='Manage Members - Kaiser Permanente'`, likely the same root cause, unconfirmed with the fix).
5. A debug scaffold (local copy of `SwitchToDelegatedAccount.xaml` at `ProcessLayer/SwitchToDelegatedAccount_Debug.xaml`, wired via `InvokeWorkflowFile` in place of the compiled `gkg:SwitchToDelegatedAccount`) is stashed (`git stash list`, message "BT-75495 Terminations debug scaffolding...") on the Terminations branch — restore only if resuming live Studio debugging there; otherwise drop it and revert `InitEnvironment.xaml` to call the real `gkg:SwitchToDelegatedAccount` before opening a PR.
6. Then, **one at a time**, map + fix + test + PR + comment-on-Jira for the remaining 3 processes: `Advising_Kaiser_PacketCollection`, `Kaiser_CA_NewHireEnrollment` (already wired+committed locally on its own branch, same as Terminations — also needs the `1.559.22` bump + retest), `Kaiser_GroupSubmissions_NewPlan`.
7. Still needs a first real end-to-end test: `Kaiser_GroupSubmissions_MemberLevel_Modern` — the only process on the **standalone** `Gusto_Benefits_Kaiser_CA` lib (different codebase, doesn't have the `tableCol`/`DebuggerApi` fix — would need the same fix ported there if it hits the same table).
8. `.local-test-feed/` exists untracked at repo root (scratch nupkgs/sources.json) — never git-add, clean up when done.
9. **Prod asset update (confirmed by user 2026-09-10), once all 6 processes are live in Production**: (a) update `Credential_Kaiser_CA` with the Delegate Account's username/password; (b) create the `Kaiser_DelegateAccountName` Text asset in **Production** (mirror Staging's Global scope, folders `Benefits`+`Benefits/CarrierAutomation`). Writing Credential values via `uip` CLI gets 403 — manual via Orchestrator UI. Do this AFTER all 6 process PRs are in Prod, not before.
10. **Reusable pattern for testing:** replicate a real Successful Prod queue item into the Staging queue via `uip or queue-items get --output-filter "SpecificContent"` (Production tenant) → compact with PowerShell `ConvertTo-Json -Compress` to a BOM-free temp file → `uip or queue-items add` (Staging tenant) with `--specific-content`. Always clean up scratch files containing real PII afterward (`rm` the temp JSON).

## FINAL STATUS 2026-09-11 — all 6 processes confirmed, all 7 PRs open, awaiting approval

All 6 impacted processes (`Kaiser_CA_MemberUpdates`, `Kaiser_CA_Terminations`, `Kaiser_CA_NewHireEnrollment`, `Advising_Kaiser_PacketCollection`, `Kaiser_GroupSubmissions_NewPlan`, `Kaiser_GroupSubmissions_MemberLevel_Modern`) confirmed end-to-end in Staging: login → MFA (Get Passcode) → delegate-switch (account-delegation → switched into delegate's book of business → client-overview → Small Business) all succeed consistently. Any downstream failures during testing were unrelated legitimate business exceptions (expired collection windows, already-burned test records, incomplete test payloads) or environment issues (VDI network share), never the delegate-switch fix itself.

**7 PRs open, dependency-ordered merge required** (shared root `dependencylock.json` means a process PR merging before its library PR fails Buildkite's `check_dependency.sh`):
1. #3311 — `Gusto_Benefits` (mega-lib, strict-selector fix, 1.559.23) — merge first
2. #3312 — `Gusto_Benefits_Kaiser_CA` (standalone lib, ported SwitchToDelegatedAccount, [1.2.2]) — independent of #3311, can merge in parallel
3. After #3311: #3310 (MemberUpdates), #3313 (Terminations), #3314 (NewHireEnrollment), #3315 (PacketCollection), #3316 (NewPlan) — any order among these 5
4. After #3312: #3317 (MemberLevel_Modern)

Oscar asked (via Slack, 2026-09-10) to approve in that order; user (Diogenes) will do the actual merges himself, in sequence, once approved.

**After all 6 processes are live in Production:** manually update `Credential_Kaiser_CA` (Delegate Account username/password) and create the `Kaiser_DelegateAccountName` Text asset in the **Production** Orchestrator tenant (mirroring Staging's Global scope, folders `Benefits`+`Benefits/CarrierAutomation`). Writing Credential values via `uip` CLI returns 403 — must be done manually via the Orchestrator UI. This is the last remaining step to fully close BT-75495.

## Lessons learned this session (see linked feedback memories for full detail)

1. **[[feedback_kaiser_ca_packetcollection_dead_duplicate_folder]]** — spent a full migration effort (Legacy→Windows) on `Packet_Collection/Kaiser_CA/`, a dead/orphaned duplicate sharing the same `projectId` as the real, live `Packet_Collection/Kaiser/` folder. Only caught when `uip or processes create` returned `409: name already used`. Lesson: verify a repo folder against the exact process/package name in the ticket + an Orchestrator lookup, never just carrier/state-naming plausibility — even a matching `projectId` doesn't guarantee it's the live one.
2. **[[feedback_gusto_benefits_net45_dropped_legacy_incompatible]]** — recent `Gusto_Benefits` versions only ship `net8.0-windows7.0`, no `net45`; any process still on `targetFramework: Legacy` breaks on ANY dependency bump (not just the new activity) once it needs a modern build.
3. **[[feedback_pack_reads_whatever_branch_is_checked_out]]** — `uip rpa pack` reads whatever's on disk for the CURRENTLY checked-out branch, repo-wide; packing a library while a different (process) branch happens to be checked out silently packs the wrong/stale content.
4. **[[feedback_uip_queue_items_get_repascalizes_keys]]** — `uip or queue-items get --output-filter SpecificContent` re-serializes keys in PascalCase even when the real expected format is camelCase (per the process's own JSON Schema file); nested objects/arrays must stay as JSON-encoded strings, Orchestrator's flat SpecificContent model rejects real nested objects.
5. **`UiPath.ConnectionClient` version pin** (Kaiser_GroupSubmissions_NewPlan) — no dependency in the graph declares a floor above 2.0.7, but the published `Gusto_Benefits` binary has a hard reference to 2.0.15.0 baked in from build time; explicit pin in the consuming project's `project.json` was the fix. Not yet promoted to its own memory file, but a real, reusable "Could not load file or assembly" root cause distinct from the develop/worktree-diff pattern in [[feedback_assembly_load_error_check_worktree_diff]].
6. **`Kaiser_GroupSubmissions_MemberLevel_Modern` doesn't use an Orchestrator queue at all** — neither it nor its legacy (currently-live, different `projectId`) counterpart use `GetQueueItems`; both pull transactions directly from Salesforce via SOQL (`GetSalesForceRecords`). The `QueueName` key in `Data/config.json` is vestigial/label-only. Don't assume "queue" in a process description always means a real Orchestrator Queue Definition — check the actual data-fetch mechanism in the workflow before trying to replicate/create queue items.
7. Buildkite two-dot-diff hygiene mattered again: every process branch needed `git merge origin/develop --no-edit` right before opening its PR (unrelated `WV_WTH_TPA` and `Kaiser_CA_MemberUpdates` commits had landed on `develop` since branch creation) — see [[feedback_check_dependency_before_pr]]/CLAUDE.md's Buildkite Rule.

## URGENT UPDATE 2026-09-11 ~01:30 — user updated Credential_Kaiser_CA in Prod BEFORE any PR merged

User swapped `Credential_Kaiser_CA` to the Delegate Account credentials directly in Production, ahead of the code fix being merged/deployed. Discovered this creates risk for processes sharing that credential that AREN'T part of this ticket's fix:
- `Kaiser_Reconciliation` — out of scope, no fix planned. Its queue trigger was **already disabled** (found pre-existing, not touched).
- `Kaiser_GroupSubmissions_MemberLevel` (legacy, no "_Modern", different `projectId`, currently live in Prod v1.31.1) — out of scope, no fix planned, no Orchestrator queue (pulls from Salesforce directly via SOQL), so no trigger to disable via this route.

**Mitigation applied:**
1. Created `Kaiser_DelegateAccountName` Text asset in **Production** (Global scope, value "Michael Hutto", shared with `Benefits`+`Benefits/CarrierAutomation` — mirrors Staging exactly, key `1163d7f9-e870-49c7-9949-047da67e3f71`).
2. Disabled the Time triggers (all `uip or triggers update <key> --type time --folder-path "Benefits" --disabled`) for the 5 in-scope processes already live in Prod, so they stop firing with the now-mismatched credential until their PRs merge+deploy:
   - `Kaiser_CA_MemberUpdates` (trigger `834180ae-5891-46d3-ad50-88f850dd0d74`)
   - `Kaiser_CA_Terminations` (`c5b225c4-ecda-43fa-817c-d8c010a5fab9`)
   - `Kaiser_CA_NewHireEnrollment` (`1e0edd85-97b3-4cdc-a0c2-b04341da9a8d`)
   - `Advising_Kaiser_PacketCollection` (`6b13446a-47be-43d3-86f2-0675583c72bc`)
   - `Kaiser_GroupSubmissions_NewPlan` (`a0a922b0-af84-4149-b4e5-9b7dec337df0`)
3. **Still NOT mitigated:** `Kaiser_Reconciliation` (146 queue items pending, trigger already off so no auto-fire risk, but manual job starts would still hit the credential mismatch) and legacy `Kaiser_GroupSubmissions_MemberLevel` (no trigger to disable, runs some other way — not yet investigated how it's actually invoked if not schedule/queue).

**Next required action once PRs merge and deploy to Prod:** re-enable all 5 triggers above (`--enabled` instead of `--disabled`, same trigger keys).

**How to apply:** read this memory first when resuming BT-75495. Check the 8 PR numbers above for current merge status, and check whether the 5 triggers above have been re-enabled yet, before trusting anything above as still accurate.

## UPDATE 2026-09-11 — all 7 PRs approved, user merging one at a time

All 7 PRs (#3310–#3317) approved. User is manually merging them now, in the dependency order above (libs #3311/#3312 first, then the 5 dependents, then #3317 last). Once all 6 processes are deployed to Prod (Buildkite auto-deploys to Prod on merge to develop), the 5 disabled triggers still need to be re-enabled (see above) — that's the last open item to fully close this ticket.

## UPDATE 2026-09-11 14:16 — PR #3310 hit a merge conflict, resolved

PR #3310 (`Kaiser_CA_MemberUpdates`) showed `mergeable_state: dirty` because the other 5 PRs had already merged into `develop` first, per the [[feedback_shared_root_dependencylock_conflicts]] pattern. Two conflicts, both expected: `Kaiser_CA_MemberUpdates/project.json` (kept ours: `Gusto_Benefits 1.559.23`, `projectVersion 1.0.8` — already newer than develop's stale `1.559.22`/`1.0.7`) and root `dependencylock.json` (took develop's version wholesale — it's the descendant lock, already includes our `1.559.23` bump plus `Gusto_Benefits_Kaiser_CA 1.2.2` from #3312). Resolved via `git merge origin/develop --no-edit` on branch `BT-75495-Kaiser-Login-delegate-account-navigation`, pushed, Buildkite green, **merged successfully 2026-09-11 14:16:34**.

**All 7 PRs (#3310–#3317) now merged into develop.** Next: confirm Buildkite auto-deployed all 6 processes to Prod, then re-enable the 5 disabled triggers (MemberUpdates, Terminations, NewHireEnrollment, PacketCollection, NewPlan — trigger keys listed above) — last step to close BT-75495.

## RESOLVED 2026-09-11 ~19:35 — Prod deploy of #3310 (Kaiser_CA_MemberUpdates) retried, passed; all 5 triggers re-enabled — TICKET FULLY CLOSED

Buildkite build #14509 first failed on an unrelated flaky analyzer race (see [[feedback_buildkite_analyzer_race_intermittent]] — NOT the creds-share issue originally suspected). User hit Retry, build passed, `Kaiser_CA_MemberUpdates 1.0.8` confirmed published to Prod (`uip or packages list -s Kaiser`, timestamp 2026-09-11T19:35:51Z).

Verified all 5 in-scope packages live in Prod before touching triggers:
- `Kaiser_CA_MemberUpdates 1.0.8`, `Kaiser_CA_Terminations 1.1.4`, `Kaiser_CA_NewHireEnrollment 1.1.2`, `Advising_Kaiser_PacketCollection 1.11.15`, `Kaiser_GroupSubmissions_NewPlan 2.0.13` — all `UiPathCLI`-published today.

Re-enabled all 5 previously-disabled Time triggers (`uip or triggers update <key> --type time --folder-path "Benefits" --enabled`), same keys as the disable action above — all returned "Updated successfully":
- `Kaiser_CA_MemberUpdates` (`834180ae-5891-46d3-ad50-88f850dd0d74`)
- `Kaiser_CA_Terminations` (`c5b225c4-ecda-43fa-817c-d8c010a5fab9`)
- `Kaiser_CA_NewHireEnrollment` (`1e0edd85-97b3-4cdc-a0c2-b04341da9a8d`)
- `Advising_Kaiser_PacketCollection` (`6b13446a-47be-43d3-86f2-0675583c72bc`)
- `Kaiser_GroupSubmissions_NewPlan` (`a0a922b0-af84-4149-b4e5-9b7dec337df0`)

`Credential_Kaiser_CA` and the Prod `Kaiser_DelegateAccountName` asset were already updated/created earlier (see "URGENT UPDATE" section above). **BT-75495 has no remaining open items** — all 6 processes live in Prod, all triggers back on, credential + asset in place. Still explicitly out of scope, unaddressed: `Kaiser_Reconciliation` (trigger stays off, pre-existing) and legacy `Kaiser_GroupSubmissions_MemberLevel`.
