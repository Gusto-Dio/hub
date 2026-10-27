---
name: feedback_buildkite_production_only_autodeploy
description: "The repo's Buildkite pipeline (.buildkite/) only auto-deploys to the Production Orchestrator tenant on merge to develop; there is no automated Staging deploy at all"
metadata:
  node_type: memory
  type: reference
  originSessionId: 5a5b1007-4059-4b74-9ec8-52734257d1e6
  modified: 2026-09-10T04:09:47.529Z
---

`.buildkite/README.md` states the pipeline is explicitly for "deploying UiPath RPA projects to UiPath Orchestrator (`gustoinc`, tenant `Production`)" — `deploy.ps1`'s credential JSON hardcodes `"orchestrator_tenant": "Production"`. On every push to `develop`, changed Libraries/Processes get packed and deployed to Production automatically. **There is no Buildkite step that publishes anything to Staging, ever.**

**How to apply:** to test a library or process fix in Staging before merge, publishing is always a manual step:
- Library packages → `uip or libraries upload --file <nupkg>` (see [[feedback_uip_libraries_vs_packages_upload]] for why not `packages upload`)
- Process packages → pack + publish/deploy manually via the equivalent Orchestrator process flow, same idea

Don't assume merging to `develop` gets you a Staging-testable artifact "for free" — it doesn't, it only ships to Production.
