---
name: reference-check-version-checks-against-production
description: "Buildkite check_version.sh always compares the new projectVersion against the Production tenant, regardless of deploy target"
metadata:
  node_type: memory
  type: reference
  originSessionId: 99fb0cb1-932f-4128-9c49-3ecef1d2a49e
  modified: 2026-10-02T02:24:35.025Z
---

`.buildkite/check_version.sh` hardcodes `HOST="https://cloud.uipath.com/gustoinc/Production/orchestrator_"` — it always fetches the current published version from the **Production** tenant's Orchestrator OData API (`GetProcessVersions` / `GetVersions`) to compare against the new `project.json` → `projectVersion`, even when the PR/deploy target is Staging or anything else.

**How to apply:** when bumping `projectVersion` for a PR, the new version only needs to be higher than what's currently live in **Production** (`uip or packages versions <name>` while logged into the Production tenant) — not higher than whatever stray/test versions might exist in the Staging feed. Staging feeds can accumulate untracked test package versions from ad-hoc local testing (pack + upload with a throwaway version number) that have nothing to do with what ships — don't let those confuse the real version bump needed for the PR. See [[project_bt76186_bsca_nhe_langpref_selector]] for a concrete case.
