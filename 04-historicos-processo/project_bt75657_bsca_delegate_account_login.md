---
name: project_bt75657_bsca_delegate_account_login
description: "BT-75657 - BSCA (Blue Shield of CA) 6 processes need login updated for new RPA Delegate Account. Login-selector fix DONE. GetAccessCode symptom (empty out_AccessCode) had NOTHING to do with the XAML — real root cause CONFIRMED 2026-09-12: Gmail filter for label 'Access Token (BSCA)' stopped matching after the Delegate Account switch changed the MFA sender. Fixed by editing the Gmail filter, zero code change needed."
metadata: 
  node_type: memory
  type: project
  originSessionId: c349854d-7105-424b-82ab-0fc005ec86f3
  modified: 2026-09-14T16:25:23.645Z
---

**Ticket:** BT-75657 (reporter Tammy Borders, auto-created from Slack #bentech-rpa-benops-support-dev,
follow-up to BT-75373 which had a username-typo blocker, now resolved). 6 BSCA processes need
`Credential_BSCA` updated to the new RPA Delegate Account credentials (1Password item "Blue Shield
California Delegate", portal `https://www.blueshieldca.com/producer/login.sp`).

**6 impacted processes:** `Advising_BSCA_PacketCollection`, `BSCA_GroupSubmissions_GroupLevel`,
`BSCA_GroupSubmissions_MemberLevel`, `BSCA_MemberUpdates`, `BSCA_NewHireEnrollment`, `BSCA_Terminations`.
All share the single Orchestrator asset `Credential_BSCA` (Global scope, folder `Benefits`, key
`4483c928-d1fa-4730-aa69-467250ac403c`) — **user already updated this in Production manually** before any
code fix, same "credential swapped ahead of code" risk pattern as Kaiser BT-75495.

**Branch:** `BT-75657-BSCA-Delegate-Account-login-selector-fix`, off `origin/develop`. **Nothing committed
yet** — everything below is still uncommitted working-tree state.

## Fix #1 — Login MFA selector (DONE, solid, keep)

`Libraries/Gusto_Benefits/BSCA/Generic/LoginToBSCA.xaml`, activity `Click_9` "Click 'Email'" (Select
Authentication Method screen): selector was hardcoded to a literal masked email
(`visibleinnertext='Email at ca****@gusto.com'`) that doesn't match the real screen after the credential
swap (confirmed live in a Prod job log: `SelectorNotFoundException`, closest match was a *different* masked
email). Fixed by making the selector tolerant: `visibleinnertext='Email at *@gusto.com'` — same wildcard
convention already used elsewhere in this same file (e.g. `aaname='*Your password will expire in*'`).
**This part of the fix is confirmed working** — the "Email" MFA option now gets clicked correctly.

## Fix #2 — GetAccessCode OnlyUnreadMessages (ATTEMPTED, FAILED, REVERTED)

**Precedent that motivated this:** [[project_bcbs_tx_newhireenrollment_stale_login_after_error]] (BT-75274) —
Hari changed a Gmail filter that started marking messages as read on arrival in the shared automation
mailbox, breaking `OnlyUnreadMessages="True"` for BCBS_TX, and per that memory's own note, "recurring and
hitting other carriers (Anthem, UHC)" too. Fix there: `OnlyUnreadMessages="False"` + `MarkAsRead="False"`,
relying only on the existing date-window filter (`msg.Date >= wbStartTime.AddSeconds(-30)`, newest first) —
in a **different, BCBS_TX-specific** library (`Gusto_Benefits_BCBS-TX-IL`).

**What was tried:** same edit applied to `Libraries/Gusto_Benefits/Generic/GetAccessCode.xaml` — the
**shared** file used by **11 carrier logins**, not just BSCA: `BSCA`, `Kaiser_CA`, `Anthem` (Broker + ER
Access), `UnitedHealthcare`, `Guardian`, `FloridaBlue`, `DeltaDental`, `CoveredCal`, `Beam`. User explicitly
chose to apply it at the shared-library level (accepting that blast radius) rather than a BSCA-local fork,
after confirming from this exact codebase's own memory that the underlying Gmail-filter fragility is
real and already documented as recurring.

**Result — did NOT fix BSCA, live-tested in Studio (`Advising_BSCA_PacketCollection`, job
`678ff82b-d434-4494-92b8-16eefe623135`, 2026-09-11 ~22:34-22:37):**
- `GetAccessCode` logged `wbStatus: Successful` but took **96.5 seconds** (over its own 90s while-loop
  budget) — "Successful" here does NOT mean a code was found, the workflow has no explicit
  found-vs-timed-out branch, it just falls through when the while condition goes false either way.
- User confirmed via **watching the actual mailbox live**: the MFA email arrived in
  `"Access Token (BSCA)"` **quickly** (not a delivery-delay problem), and the folder currently has only
  **16 messages total** — ruling out the "too many historical messages making each Top=100 IMAP poll slow"
  performance theory that was the first hypothesis.
- User confirmed: **the robot never typed any code** — i.e. `out_AccessCode` came back empty after the
  full 90s+ loop, despite the right email sitting in the folder the whole time.
- **Leading (unconfirmed) hypothesis at pause time:** the code-extraction regex in `GetAccessCode.xaml`
  (`[\s|>](\d{4,})[\s|<]`, requires a 4+ digit run bounded by whitespace or a tag boundary) may not match
  Blue Shield's actual MFA email HTML structure — if the regex fails, `matchRgx.Match(...).ToString` is
  empty, `cleanRgx.Replace("","")` is still empty, `out_AccessCode` stays empty/whitespace, and the `While`
  loop's condition (`String.IsNullOrWhiteSpace(out_AccessCode)`) stays true — so it would keep re-fetching
  and re-matching the **same** email over and over until the 90s cutoff, never advancing. This is
  consistent with everything observed (fast arrival, only 16 messages, "Successful" status, empty typed
  field) but **was not directly confirmed** — never got to actually read the email's raw body/HTML before
  the user decided to pause and revert.

**Decision (user's call, 2026-09-11): REVERTED Fix #2 entirely** — "para não quebrar os outros [carriers],
até saber o que está rolando." `Libraries/Gusto_Benefits/Generic/GetAccessCode.xaml` is back to its exact
`develop` state (`git diff` confirmed empty for this file) — `OnlyUnreadMessages="True"`,
`MarkAsRead="True"`, unchanged. This turned out to be the right call — see below, the regex/extraction
hypothesis was WRONG too, the real cause was entirely outside the codebase.

## Fix #2 — REAL root cause CONFIRMED 2026-09-12: Gmail filter, not code, not GetAccessCode.xaml at all

Resumed session 2026-09-12: rebuilt `Advising_BSCA_PacketCollection` against Staging with
`Gusto_Benefits 1.559.26` (login-selector fix kept, `GetAccessCode.xaml` fully untouched/reverted —
see pack/publish steps below) and re-ran in Studio while the user watched the mailbox live.

**Root cause:** `benefitsoperations@gusto.com` has a Gmail filter that applies the label
`Access Token (BSCA)` — the exact label `GetIMAPMailMessages` in `GetAccessCode.xaml` queries via
`MailFolder="[in_GmailFolder]"`. The filter's `From` criterion was
`from:("Blue Shield of California" via Carrier Operations)` — the `via Carrier Operations` fragment is
Gmail's own annotation, shown when the sending path/SPF doesn't align with the display domain (i.e. the
*old* (non-delegate) BSCA account's MFA email was relayed through some intermediary). After the RPA
Delegate Account credential switch, BSCA's MFA email is now sent **directly** as
`Blue Shield of California <WDHwebdesk2@blueshieldca.com>` — no `via` wrapper — so the filter's `From`
match silently stopped firing, the label was never applied, and `GetIMAPMailMessages` (querying by label)
never found the message. This exactly explains every symptom observed in the 2026-09-11 test: fast
delivery, only 16 messages in the target label/folder (because nothing new was landing there), `wbStatus:
Successful` (the while-loop just timed out, no found/not-found branch), and `out_AccessCode` staying
empty — **nothing to do with the extraction regex, nothing to do with `OnlyUnreadMessages`.** The
BCBS_TX/BT-75274 precedent ([[project_bcbs_tx_newhireenrollment_stale_login_after_error]]) pointed at the
right *class* of problem (a Gmail filter silently broken by a mail change) but the wrong specific
mechanism — that one was read/unread, this one is label/routing via sender-string matching.

**Fix (zero code change):** user created a new Gmail filter on `benefitsoperations@gusto.com` matching
`from:(WDHwebdesk2@blueshieldca.com)` + `subject:(Your one-time verification code)` → apply label
`Access Token (BSCA)`. **Confirmed working** — re-ran `Advising_BSCA_PacketCollection` in Studio, the
MFA email got the label, `GetAccessCode` found it and **typed the code successfully**.

**Implication for the PR/ticket:** the original `GetAccessCode.xaml` logic was never broken — no library
change needed for Fix #2 at all, the earlier revert was exactly correct. The only real code change for
this ticket is Fix #1 (login selector). Worth a note in the Jira ticket/PR that BSCA's MFA delivery
depends on an external Gmail filter tied to the sender address, since it broke silently once already and
could again (e.g. if the Delegate Account's sending address changes again, or for any other carrier that
goes through a Delegate Account switch and has a similar filter). See new memory
[[feedback_gmail_via_filter_breaks_after_sender_change]] for the generalizable lesson.

**Do NOT re-attempt any change to the shared `Generic/GetAccessCode.xaml` for this symptom** — confirmed
not the cause.

## State as of 2026-09-12 (resume here)

- `Libraries/Gusto_Benefits/project.json`: `projectVersion` **`1.559.26`** (login-selector fix kept,
  GetAccessCode untouched). **Packed and published to the Staging library feed ✅** (2026-09-12).
- `Advising_BSCA_PacketCollection`'s `project.json` bumped `Gusto_Benefits` `1.559.25` → `1.559.26` ✅,
  rebuilt clean against Staging ✅, **re-tested live in Studio ✅ — confirmed working end-to-end through
  login → MFA "Email" click → GetAccessCode (after the Gmail filter fix) → code typed successfully.**
- Staging feed has stale/bad packages from the abandoned attempt: `Gusto_Benefits.1.559.24` (login-selector
  fix only, harmless/superseded) and `Gusto_Benefits.1.559.25` (login fix + the bad GetAccessCode change,
  wrong) — don't let any process resolve to `1.559.25` going forward; only `1.559.26` is correct.
- **All 6 BSCA processes bumped to `Gusto_Benefits: "1.559.26"`, rebuilt clean, and LIVE-TESTED IN STUDIO
  SUCCESSFULLY ✅✅✅✅✅✅** (2026-09-12): `Advising_BSCA_PacketCollection`, `BSCA_GroupSubmissions_GroupLevel`,
  `BSCA_GroupSubmissions_MemberLevel`, `BSCA_MemberUpdates`, `BSCA_NewHireEnrollment`, `BSCA_Terminations`.
  Pre-PR checklist (min 2-3 transactions tested) satisfied for all 6, not just the minimum.
- **Unrelated pre-existing bug hit mid-testing, fixed:** `BSCA_GroupSubmissions_MemberLevel` failed to compile
  in Studio with `Could not load file or assembly 'ConnectionClient, Version=2.0.15.0...'` from
  `Gusto_Benefits.AWS.GetS3Census` — same known issue as Kaiser's ([[feedback_connectionclient_assembly_load_needs_explicit_pin]]),
  nothing to do with this ticket's actual fix. Fixed by adding `"UiPath.ConnectionClient": "2.0.15"` to the
  process's own `project.json`, confirmed via rebuild. **Applied the same pin preventively to `BSCA_MemberUpdates`,
  `BSCA_NewHireEnrollment`, `BSCA_Terminations`** (none had it) so the user doesn't hit the same error 3 more
  times — all rebuilt clean. `BSCA_GroupSubmissions_GroupLevel` and `Advising_BSCA_PacketCollection` did NOT
  need the pin and passed without it (non-deterministic — depends on local NuGet cache state per project, not
  something that reliably reproduces).
## PRs OPENED ✅ (2026-09-12) — all 7, nothing merged yet

Split the 8 modified files into 7 separate branches/PRs (one per component, each created fresh off
`origin/develop` so each PR's diff is scoped to only its own files — verified via `git status`/`git diff`
after each checkout that no other component's changes leaked in):

1. **Lib** — PR [#3320](https://github.com/Gusto/biztech-uipath-rpa/pull/3320), branch
   `BT-75657-BSCA-Delegate-Account-login-selector-fix` — `LoginToBSCA.xaml` fix + lib `project.json`
   1.559.26 + root `dependencylock.json` bump (`Gusto_Benefits` 1.559.26, added `UiPath.ConnectionClient`
   2.0.15). **Merge this FIRST.**
2. PR [#3321](https://github.com/Gusto/biztech-uipath-rpa/pull/3321) — `Advising_BSCA_PacketCollection`,
   branch `BT-75657-BSCA-PacketCollection-dependency-bump`
3. PR [#3322](https://github.com/Gusto/biztech-uipath-rpa/pull/3322) — `BSCA_GroupSubmissions_GroupLevel`,
   branch `BT-75657-BSCA-GroupSubmissions-GroupLevel-dependency-bump`
4. PR [#3323](https://github.com/Gusto/biztech-uipath-rpa/pull/3323) — `BSCA_GroupSubmissions_MemberLevel`
   (+ ConnectionClient pin), branch `BT-75657-BSCA-GroupSubmissions-MemberLevel-dependency-bump`
5. PR [#3324](https://github.com/Gusto/biztech-uipath-rpa/pull/3324) — `BSCA_MemberUpdates` (+
   ConnectionClient pin + its own `dependencylock.json` bump — see below), branch
   `BT-75657-BSCA-MemberUpdates-dependency-bump`
6. PR [#3325](https://github.com/Gusto/biztech-uipath-rpa/pull/3325) — `BSCA_NewHireEnrollment` (+
   ConnectionClient pin, preventive), branch `BT-75657-BSCA-NewHireEnrollment-dependency-bump`
7. PR [#3326](https://github.com/Gusto/biztech-uipath-rpa/pull/3326) — `BSCA_Terminations` (+
   ConnectionClient pin, preventive), branch `BT-75657-BSCA-Terminations-dependency-bump`

**Buildkite gotcha specific to this ticket, checked and handled:** of the 6 processes, only
`BSCA_MemberUpdates` does NOT have `"update_dependency"` in its `settings.json` `skipTests` — so it's the
only one where `check_dependency.sh` actually runs and does an exact-string match against the root
`dependencylock.json`. Since that lock file still has `Gusto_Benefits: 1.559.23` and no
`UiPath.ConnectionClient` entry at all on `develop`, PR #3324 duplicates the same `dependencylock.json`
bump that's in the lib PR #3320, so it passes CI on its own regardless of merge order (identical target
values, no conflict expected when both land). All other 5 processes skip `update_dependency` so the lock
file state doesn't affect them. `check_version.sh` runs for all 6 (none skip `update_version`) — confirmed
via `uip or packages versions <name> --sort-by "Version desc"` in Production that every bumped
`projectVersion` here is higher than what's currently published (e.g. `Advising_BSCA_PacketCollection`
1.18.12→1.18.13, `BSCA_GroupSubmissions_GroupLevel` 5.1.2→5.1.3, `BSCA_GroupSubmissions_MemberLevel`
6.2.12→6.2.13, `BSCA_MemberUpdates`/`BSCA_NewHireEnrollment` 7.0.7→7.0.8, `BSCA_Terminations` 7.0.3→7.0.4).
The lib itself skips both `update_version` and `update_dependency` (confirmed in its own `settings.json`),
so none of this applies to PR #3320's own build.

**Comment posted on Jira BT-75657** (2026-09-12, comment id 4840579) — kept simple per user's request:
explains that besides the Delegate Account credential swap, a small login fix was needed to select the
right "Email" MFA option (old selector expected the old masked email). Deliberately did NOT mention the
GetAccessCode/Gmail-filter investigation in the Jira comment (user asked for something "bem simples") —
that detail lives only in this memory + the PR #3320 body, not in the ticket itself.

**All 7 PRs APPROVED ✅ (2026-09-14)** — #3320 (lib) through #3326, approved in the order listed above.
No Slack approval request needed after all — approvals came in directly. User will do the actual merges
himself (same division of labor as Kaiser BT-75495).

**PR #3320 (lib) merged + deployed ✅ (2026-09-14, Buildkite build #14523 finished `passed`).** Deploy
took 5 attempts (job + 4 manual retries) before passing — same intermittent single-agent credentials-share
flake documented in [[feedback_buildkite_creds_share_intermittent]] (agent `uscol1-kibana-1`), not a real
code/PR issue. `Gusto_Benefits 1.559.26` is now live in Production.

## Merge + deploy status as of 2026-09-14 ~13:56 (checked via GitHub `pull_request_read` + Buildkite `list_builds`/`get_build`)

User is merging the 6 process PRs in sequence himself. Status:

| PR | Process | Merged? | Deploy build |
|---|---|---|---|
| #3320 | Lib Gusto_Benefits | ✅ | ✅ passed (#14523, after 5 attempts) |
| #3321 | Advising_BSCA_PacketCollection | ✅ (13:40) | ✅ passed (#14526 — 1st attempt #14525 failed, same creds-share flake) |
| #3322 | BSCA_GroupSubmissions_GroupLevel | ✅ (13:43) | ✅ passed (#14532) |
| #3323 | BSCA_GroupSubmissions_MemberLevel | ✅ (13:52) | ✅ passed (#14539) |
| #3324 | BSCA_MemberUpdates | ✅ (13:44) | ✅ passed (#14536) |
| #3325 | BSCA_NewHireEnrollment | ✅ (13:58) | ⏳ #14543 `running` as of last check |
| #3326 | BSCA_Terminations | ✅ (13:55) | ✅ passed (#14541, confirmed on recheck) |

**All 7 PRs merged ✅ (2026-09-14, ~13:58).**

**Verified Production version-by-version (2026-09-14 ~14:03)** — switched CLI tenant from Staging to
Production first (`uip login tenant set Production`; `uip login status` had defaulted to Staging, per
[[feedback_uip_default_tenant_not_production]]). Checked each package's actual live version in Prod via
`uip or packages versions <name>` (processes) / `uip or libraries versions Gusto_Benefits` (**lib only** —
`uip or packages versions Gusto_Benefits` returns the WRONG feed for libraries, stuck showing a stale
1.537.6 from May; libraries are tenant-scoped and need the separate `libraries` subcommand, see
[[feedback_uip_libraries_vs_packages_upload]]):

| Component | Expected version | Live in Prod | Match |
|---|---|---|---|
| Lib Gusto_Benefits | 1.559.26 | 1.559.26 | ✅ |
| Advising_BSCA_PacketCollection | 1.18.13 | 1.18.13 | ✅ |
| BSCA_GroupSubmissions_GroupLevel | 5.1.3 | 5.1.3 | ✅ |
| BSCA_GroupSubmissions_MemberLevel | 6.2.13 | 6.2.13 | ✅ |
| BSCA_MemberUpdates | 7.0.8 | 7.0.8 | ✅ |
| BSCA_NewHireEnrollment | 7.0.8 | **7.0.7 (stale)** | ❌ |
| BSCA_Terminations | 7.0.4 | 7.0.4 | ✅ |

**Real gap found (as of ~14:03):** build #14543 (deploy of #3325, BSCA_NewHireEnrollment) had come back
`failed` — Prod was still on the old 7.0.7 package at that point. Same `uscol1-kibana-1` credentials-share
flake as the others; **resolved on retry** — reconfirmed 2026-09-14 ~16:19 UTC via `uip or packages list`
+ `uip or processes list --folder-path Benefits --name BSCA`: `BSCA_NewHireEnrollment` is now `7.0.8` live
in Prod (package published 16:19:03Z), matching the other 5. **All 6 processes + the lib are now 100%
confirmed on their target versions in Production, release pointers included** — ticket fully closed, no
outstanding Orchestrator work. Lib `Gusto_Benefits` also showed `1.559.27` in the libraries feed (one
patch above this ticket's `1.559.26`, published 16:14:33Z) — from an unrelated later merge, not a problem
for this ticket.
- Nothing on this branch has been committed to git yet. `git status` should show modified:
  `Libraries/Gusto_Benefits/project.json`, `Libraries/Gusto_Benefits/BSCA/Generic/LoginToBSCA.xaml` (the
  real fix), and the 6 processes' `project.json` files (dependency + own projectVersion bumps, see below) —
  `Libraries/Gusto_Benefits/Generic/GetAccessCode.xaml` should show **zero diff** (reverted, confirmed correct).
- 6 processes' own `projectVersion` bumps already applied (independent of the lib version, these don't need
  to change again): `Advising_BSCA_PacketCollection` 1.18.12→1.18.13, `BSCA_GroupSubmissions_GroupLevel`
  5.1.2→5.1.3, `BSCA_GroupSubmissions_MemberLevel` 6.2.12→6.2.13, `BSCA_MemberUpdates` 7.0.7→7.0.8,
  `BSCA_NewHireEnrollment` 7.0.7→7.0.8, `BSCA_Terminations` 7.0.3→7.0.4.

## Other findings from this session

- `Credential_Gmail` (shared automation mailbox used by `Generic/GetAccessCode.xaml` across all 11
  carriers) = **`benefitsoperations@gusto.com`** — confirmed by the user checking the Orchestrator UI
  directly; the API (`uip or assets get --all-fields`) never returns Credential username/password values,
  confirmed by testing.
- See [[feedback_buildkite_analyzer_race_intermittent]] — hit the same flaky
  `Could not load file or assembly 'Microsoft.VisualStudio.Services.Common'` uipcli race during one of the
  6 processes' rebuilds (`BSCA_Terminations`); retry alone fixed it, unrelated to any of our changes.
