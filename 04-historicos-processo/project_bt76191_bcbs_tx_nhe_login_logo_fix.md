---
name: project-bt76191-bcbs-tx-nhe-login-logo-fix
description: "BT-76191 BCBS_TX_NewHireEnrollment_Modern login-faulting fix — two PRs open, both green, awaiting review"
metadata:
  node_type: memory
  type: project
  originSessionId: 2284ba82-6de5-4a01-a620-fbbaf6b1eba6
  modified: 2026-10-03T00:46:54.266Z
---

BT-76191 (Tammy Borders, 2026-09-29): `BCBS_TX_NewHireEnrollment_Modern` jobs faulting on login after only a few transactions (56 in SFDC queue / 45 in UiPath queue at open). Root cause found: `LoginToBCBSTXIL.xaml`'s "Click 'Logo'" step on the producers `showError` recovery page relied only on Computer Vision, which intermittently fails in Production — when it fails mid-transaction it trips the shared `MFA_BCBS_TX` login circuit breaker.

Split into two PRs (2026-10-03), both Buildkite-green as of this writing, awaiting review:
- **#3392** — lib fix: `Gusto_Benefits_BCBS-TX-IL` 1.2.8→1.2.9, adds FuzzySelector (`blue-access-producers-logo`) as primary selector for the logo click, CV kept as fallback.
- **#3393** — consumer pin bump: `BCBS_TX_NewHireEnrollment_Modern` projectVersion 1.5.8→1.5.9, pins the lib to 1.2.9, plus adds the `entry-points.json` manifest this project was missing (same gap as BT-75952/Oxford).

**Why:** restore the normal login flow so the bot stops burning through the MFA circuit breaker and faulting after a handful of transactions; the entry-points.json gap was found incidentally while working the branch.

**How to apply:** when picking this back up, check current PR state first — don't assume merge order.

Key surprises for next time:
- Expected the process PR (#3393) to fail CI until the lib PR (#3392) merged and published 1.2.9 to the feed (textbook library→consumer sequencing). It did **not** fail — Buildkite build passed green before #3392 merged. The actual package-restore dependency isn't enforced at PR-build time here, only `mergeable_state` was blocked (pending review), not CI. Don't block on merge-order assumptions for this repo without checking actual build logs.
- `check_dependency.sh` was already skipped for this process (`skipTests: ["update_dependency"]` in its `settings.json`), so the root `dependencylock.json` mismatch (stale at `[1.2.6]` vs. develop's actual `[1.2.8]`) never blocked anything — didn't need touching.
- [[feedback_studio_resave_diff_noise]] hit twice on `Main.xaml` during this session (pure ViewState/diagram noise, no logic change) — reverted both times before committing.

**Still open / not covered by these PRs:** the broader ask in the ticket — "log in once and move group to group without restarting login every time" — is explicitly out of scope of #3392/#3393. If BT-76191 isn't closed after these land, that's the remaining work.

**Evidence from a live Staging run (job `f744c19d-272d-41b4-a923-63975d0ad6e1`, 2026-10-02 23:02→00:18, library 1.2.9 already active):** 16 of 17 transactions completed with legitimate business/system exceptions (not login faults). The specific logo-click-recovery scenario this fix targets was never exercised in that run. The run was eventually killed by a **different, unrelated** failure: MFA access-code typing verification mismatch (`Type Into 'Access Code' 4th` expected "2", got "") during a re-login after a business exception — worth a separate ticket if it recurs.
