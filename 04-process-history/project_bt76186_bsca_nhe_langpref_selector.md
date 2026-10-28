---
name: project-bt76186-bsca-nhe-langpref-selector
description: "BT-76186 BSCA_NewHireEnrollment Language Preference selector fix — PR #3386 open"
metadata:
  node_type: memory
  type: project
  originSessionId: 99fb0cb1-932f-4128-9c49-3ecef1d2a49e
  modified: 2026-10-02T02:24:13.972Z
---

BT-76186: `BSCA_NewHireEnrollment` faulted on every scheduled run from 2026-09-25 through 2026-10-01 (last success 2026-09-24). Root cause: BSCA (Blue Shield of California) carrier portal changed the Language Preference dropdown's `data-value` format from a bare code (`NS01`) to `code - Label` (`NS01 - Not Selected`) — confirmed via the UiPath selector engine's fuzzy-match suggestions in the Production error logs (all candidates followed the new `<code> - <Label>` pattern). No repo code change coincided with the regression date — purely a carrier-side UI change. Every new-hire transaction hit `Click 'Not Selected'` in `Processes/Benefits/CarrierAutomations/MemberSubmission/BSCA/BSCA_NewHireEnrollment/ProcessLayer/EnterEmployeeInformation.xaml:690`, accumulated 6 consecutive SystemErrors, and faulted the job — queue backed up (88 SFDC / 78 UiPath per ticket).

Fix: widened the selector to `data-value='NS01*'` (wildcard). `projectVersion` bumped 7.0.9 → 7.0.10 (higher than Production's 7.0.9, satisfies Buildkite `check_version.sh`, which always checks against the Production tenant regardless of deploy target — see [[reference_check_version_checks_against_production]]). Added missing `entry-points.json` (this project didn't have one, unlike every sibling process).

**Status (2026-10-02): PR #3386 opened against `develop`, branch `BT-76186-bsca-nhe-langpref-selector`.** Jira comment posted with root cause + PR link. Not yet merged/reviewed.

**Validation:** Live-tested in Staging against real Production queue items recreated via `QueueItemRecreator` (folder "Benefits", queue "BSCA_NewHireEnrollment", `in_ReferenceIds` = queue item Key GUID). First attempts blocked by an unrelated, pre-existing issue: Staging's `Credential_BSCA` asset (Global scope, folder key `63a83647-fe7d-4e33-8257-3777b64ef3d0`) was NOT pointing to the correct (Production-matching) broker account — caused `NavigateToOnlineRenewals` to hit a dead Salesforce-hosted BSCA Community link ("URL No Longer Exists" from blueshieldcashieldlink.force.com) during the "Shop & Enroll" external-redirect step, unrelated to the selector fix. User (Dio) fixed the Staging credential manually in the Orchestrator UI (Credential assets can't be written via `uip` CLI). After the fix, a real recreated queue item (Id 2719006694) processed successfully end-to-end in Staging, 0 failures.

Staging `BSCA_NewHireEnrollment` Process (folder key `63a83647-fe7d-4e33-8257-3777b64ef3d0`, process key `E8B99A2B-2D3C-41A9-BF9B-04C644DBE9B3`) is currently bound to package version **7.0.13** — a throwaway test version packed with the real `uipcli` (not the committed `project.json` version) because the Staging feed already had stray, untracked 7.0.10–7.0.12 packages from an earlier unknown experiment that collided with the natural next version. The real PR commits `projectVersion: 7.0.10`.

**Why to care later:** if BT-76186 needs a follow-up or the PR gets revisited, check whether Staging's Process is still pointed at 7.0.13 (test package, has the fix but isn't what ships) vs whatever real version gets published after merge — rebind to the real published version once it exists.
