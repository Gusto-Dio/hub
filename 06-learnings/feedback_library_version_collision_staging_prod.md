---
name: feedback_library_version_collision_staging_prod
description: Same library version number can hold different binaries in Staging vs Production feeds — verify via nuspec repository commit before trusting a version bump
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 7805b8b2-e067-4d1a-a0fb-51eac34d780a
  modified: 2026-08-05T16:50:50.204Z
---

**Symptom:** a fix that's confirmed merged and published (e.g. `Gusto_Benefits 1.555.1` with the BT-74721 "leaving BSCA" popup-dismissal fix) still doesn't run in a local Studio debug session, even though `project.json` correctly depends on that exact version.

**Root cause found 2026-08-05 (BT-74720):** two different engineers published two different builds under the *same* version number to *different* tenant feeds — Staging had `1.555.1` published 2026-08-03 11:59 by a colleague from an unrelated feature branch (predates our fix commit), while Production had the correct `1.555.1` published 2026-08-04 08:59 by the CI pipeline from `develop`. NuGet version numbers are only unique *within* a feed, not across tenants — nothing stops this collision, and nothing warns about it.

**Why:** local Studio/`uip rpa` package restore resolves against whichever feed is configured for that machine's NuGet sources (here, Staging) and then caches the resolved `.nupkg` forever under `~/.nuget/packages/<id>/<version>/` — once cached, "reinstall" in Studio does NOT re-check the feed for content drift, it just reads the cache.

**How to detect:** download the suspect package from each tenant (`uip or libraries download "<Id>:<Version>" -d <path>`, switch tenant with `uip login tenant set <Production|Staging>`), unzip, and compare `<Id>.nuspec` → `<repository commit="...">`. Also compare raw file SHA512 — two different builds under the same version number will have completely different hashes even if the version string is identical.

**Fix that avoids opening a new library PR just to escape the collision:** don't bump to a new version number, and don't `libraries delete` the colliding package (that's a shared feed, deleting someone else's published version is destructive and `library-authoring-guide.md` explicitly reserves `delete` for mistaken-upload cleanup only). Instead, reseed the LOCAL cache only:
1. Delete `~/.nuget/packages/<id>/<version>/` (bad cached copy).
2. Delete matching entries in `AppData/Local/NuGet/v3-cache/**/nupkg_<id>.<version>.dat` and `AppData/Local/UiPath/.cache/<id>*-v<major.minor>-*.Reflection.dat` (UiPath's own compiled-reflection cache, separate from NuGet's).
3. Download the *correct* tenant's `.nupkg`, extract it into the same folder layout NuGet expects (`.nupkg`, `.nupkg.sha512` — base64 of raw SHA512 bytes, extracted `content/`/`contentFiles/`/`lib/`, lowercase `<id>.nuspec`, and a `.nupkg.metadata` JSON with `version:2`, `contentHash` matching the sha512 file, and a `source` URL — pattern copied from an existing valid cache entry of another version).
4. Re-run the debug in Studio — no feed reconfiguration, no code change, no PR needed.

**How to apply:** whenever a "this should already be fixed" library behavior doesn't reproduce locally despite the dependency version looking right, suspect a cross-tenant version collision before suspecting the fix itself or re-doing the fix. See [[project_bt74721_bsca_terminations_navigation]] for the case this was found in.
