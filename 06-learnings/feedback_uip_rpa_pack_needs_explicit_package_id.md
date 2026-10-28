---
name: feedback-uip-rpa-pack-needs-explicit-package-id
description: "uip rpa pack defaults package ID to the folder name, not project.json's \"name\" field — always pass --package-id explicitly"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: cfcf8d30-c3b5-4349-9187-f24d454cae69
  modified: 2026-09-05T01:44:56.612Z
---

`uip rpa pack` (the Claude-integrated CLI, distinct from the real `uipcli`/`UiPath.CLI.Windows` used by `.buildkite/deploy.ps1`) does **not** read the NuGet package ID from `project.json`'s `"name"` field by default. Without `--package-id`, it falls back to the **project folder's leaf name**.

**Why:** Hit this on BT-75456 — packed `UnitedHealthcare_SAM` (project.json `name`: `Advising_UHC_PacketCollection`) without `--package-id`, and it silently produced/uploaded a wrongly-named package `UnitedHealthcare_SAM:1.17.13` to the Staging Orchestrator feed — a brand-new, unrelated package entry, not a new version of the real one. Confirmed by inspecting the `.nuspec` inside the `.nupkg` directly (`<id>UnitedHealthcare_SAM</id>`).

There is **no CLI command to delete a package from the Orchestrator feed** (`uip or packages` only has `list`/`get`/`upload`/`download`/`versions`/`entry-points`, no `delete`). Cleaning up a wrongly-uploaded package requires the Orchestrator UI, done manually by a human who can visually confirm the right package before deleting — never via a raw/undocumented API call, since the blast radius on the shared feed (and on `.buildkite/deploy.ps1`, which reads from the same feed) is not fully known.

**How to apply:**
- Before running `uip rpa pack`, always check `project.json`'s `"name"` field and pass it explicitly: `uip rpa pack --package-id "<name-from-project.json>" ...`.
- Never rely on folder-name defaults when the folder name and `project.json.name` differ (common after a Legacy→Windows migration where the folder wasn't renamed to match).
- After packing, inspect the produced `.nuspec` (`unzip -p <pkg>.nupkg "*.nuspec"`) to confirm `<id>` matches the real package ID before uploading to any Orchestrator feed.
- If a wrong package still gets uploaded, do NOT attempt to delete it via API — flag it to the user and let them remove it manually via the Orchestrator UI (Packages → search → Delete), confirming visually it's the orphan, not the real one.
- See also [[project_bt75456_uhc_packetcollection_legacy_windows_migration]].
