---
name: feedback_gusto_benefits_net45_dropped_legacy_incompatible
description: Recent Gusto_Benefits (and likely other actively-maintained libs) nupkg versions only ship lib/net8.0-windows7.0, no net45 — any process still on targetFramework Legacy silently can't consume new versions of that dependency at all, not just the new activity
metadata:
  type: feedback
  originSessionId: fc2006b8-97b4-4993-82c5-23e7ef1bc824
  modified: 2026-09-10T22:22:24.100Z
---

Checked `~/.nuget/packages/gusto_benefits/<version>/lib/` across every cached version from 1.537.1 up to 1.559.23: all of them only contain `net8.0-windows7.0`, never `net45`. This means any process still pinned to `targetFramework: "Legacy"` in `project.json` cannot consume ANY version of `Gusto_Benefits` newer than whatever the last net45-compatible publish was (pre-1.537ish) — not just a specific new activity.

**Symptom that looks misleading:** running `uip rpa-legacy validate` after bumping the dependency version shows "Activity type not found" errors for activities that ALREADY existed and worked before the bump (e.g. `LoginToKaiser`), not just the new one you're trying to add (e.g. `SwitchToDelegatedAccount`). This looks like a broken/renamed activity, but the real cause is that the resolved package for the Legacy runtime has zero net45 assemblies at that version — the whole library becomes untyped for that project, not just the new piece.

**Confirmed instance:** `Advising_Kaiser_PacketCollection` (BT-75495) was still Legacy, pinned at `Gusto_Benefits 1.530.7`. Bumping straight to 1.559.23 to pick up `SwitchToDelegatedAccount` broke `LoginToKaiser` resolution too. Same root cause already hit and solved once before in [[project_bt75456_uhc_packetcollection_legacy_windows_migration]] (UHC SAM) — recognize the pattern faster next time: any Legacy-target process is a ticking time bomb the moment it needs literally any new fix from a shared lib that's already moved to modern (net8.0-windows7.0-only) packaging.

**How to apply:** before bumping a shared library dependency version on any process, check `targetFramework` in that process's `project.json` first. If it says `"Legacy"` (or the field is absent), don't just bump the version and expect validate/build errors to be about the new activity only — the process likely needs a full Legacy→Windows migration first (see [[project_bt75456_uhc_packetcollection_legacy_windows_migration]] for the established mechanical pattern: flip `targetFramework`, bump `Gusto_Generic_Activities`→2.1.1 and `Gusto_Generic_SalesForce`→2.0.1 alongside the target lib, fix the two known latent bugs — empty `ui:AddLogFields.Fields` dict on non-`SetTransactionStatus` activities, and dead `InvokeWorkflowFile` calls to a nonexistent `ProcessLayer\KillAllProcesses.xaml` that should be `g:KillAllProcesses` instead). Don't burn a debugging cycle assuming the activity itself is broken.
