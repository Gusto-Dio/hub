---
name: feedback-staging-bsca-credential-mismatch
description: "Staging BSCA Credential_BSCA asset pointed to wrong/stale broker account, broke portal navigation unrelated to code"
metadata:
  node_type: memory
  type: feedback
  originSessionId: 99fb0cb1-932f-4128-9c49-3ecef1d2a49e
  modified: 2026-10-02T02:24:27.227Z
---

When a BSCA process's Staging job fails during `NavigateToOnlineRenewals` (Init phase, before any queue item is touched) with a dead Salesforce Community link ("URL No Longer Exists" from a `*.force.com` domain) after the "Shop & Enroll" external-redirect click, suspect the `Credential_BSCA` Orchestrator asset in Staging before suspecting code or selectors.

**Why:** found during [[project_bt76186_bsca_nhe_langpref_selector]] — Staging's `Credential_BSCA` (Global-scope asset, Staging folder key `63a83647-fe7d-4e33-8257-3777b64ef3d0`) was not the correct/current broker account. Production ran the identical `NavigateToOnlineRenewals` flow successfully 6x the same day, proving the portal itself wasn't broken — only Staging's account was stale. Last successful Staging run of this process before the fix was 2026-06-16, so this had likely been broken for months without anyone noticing (Staging rarely runs this process).

**How to apply:** Credential assets can't be read or written via `uip` CLI (values are masked/write-protected) — this has to be checked and fixed manually in the Orchestrator UI. If a BSCA (or likely any carrier-portal) process fails navigation/login only in Staging while Production succeeds the same day, check whether Staging's credential asset for that carrier matches what Production actually uses before escalating to the carrier or digging into selectors.
