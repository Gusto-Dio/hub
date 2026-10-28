---
name: feedback_uip_libraries_vs_packages_upload
description: "uip or packages upload publishes to the Orchestrator Process/Automation package feed, NOT the tenant Library feed used for design-time dependency restore; use uip or libraries upload for lib packages"
metadata:
  node_type: memory
  type: feedback
  originSessionId: 5a5b1007-4059-4b74-9ec8-52734257d1e6
  modified: 2026-09-10T04:09:23.494Z
---

`uip or packages upload <file>.nupkg` and `uip or libraries upload --file <file>.nupkg` hit **different feeds**:
- `packages upload` → the Orchestrator **Process/Automation** package feed (for deploying something as a runnable Orchestrator Process via `processes create`).
- `libraries upload` → the tenant **Library** feed, the one `uip rpa packages install` / Studio's design-time NuGet restore actually pulls from for a consuming project's `dependencies`.

**Why:** During BT-75495, published a fixed `Gusto_Benefits` lib via `packages upload` first — it reported success, but `uip rpa packages install` in a consuming process kept failing with "Cannot create unknown type" for the new activity, as if the upload never happened. It had "succeeded" into the wrong feed. Switching to `uip or libraries upload` fixed it immediately.

**How to apply:** whenever publishing a Library project (not a Process) to Orchestrator for another project to consume as a `project.json` dependency, always use `uip or libraries upload`. Reserve `uip or packages upload` for actual automation packages meant to run as Orchestrator Jobs.

Also relevant: Buildkite in this repo only auto-deploys to **Production** on merge to `develop` (see `.buildkite/README.md`) — there's no CI step that publishes to Staging at all, so this manual `libraries upload` step is *always* required to test a library fix in Staging before merge, not just a one-off gap.
