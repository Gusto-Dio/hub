---
name: assembly-load-error-check-worktree-diff
description: "UiPath \"Could not load file or assembly\" errors — diff project.json against HEAD/develop before chasing NuGet cache fixes"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 7d61874a-d2ce-4226-9664-d1123441459a
  modified: 2026-09-08T20:56:18.747Z
---

When a UiPath process throws "Could not load file or assembly 'X, Version=Y...'" (e.g. `ConnectionClient`, `UiPath.Platform`) during Studio debug, check whether `project.json` has **uncommitted dependency bumps** diverging from `develop` BEFORE spending time on NuGet cache repairs, package restores, or explicit dependency pinning.

**Why:** On BT-75454 (2026-09-08), spent ~1h chasing a phantom `UiPath.ConnectionClient 2.0.11` / `UiPath.Platform 25.12.1` assembly-load error — cleared NuGet caches, hand-patched package folders (blocked by the safety classifier, correctly), pinned `UiPath.Platform` explicitly in project.json (twice, wrong version the first time, since another package's transitive floor silently overrode the pin). None of that was the actual cause. The real cause: **uncommitted local dependency bumps already sitting in the working tree before the session even started** (`Gusto_Generic_SalesForce` 1.10.0→2.0.1, `Gusto_Benefits` 1.553.2→1.559.11, `Gusto_Generic_Activities` 2.1.1→2.2.1) — nobody had documented these as intentional. Reverting `project.json`+`Main.xaml` to `HEAD` (which was byte-identical to `origin/develop`) fixed it immediately.

**How to apply:** Before deep NuGet/assembly troubleshooting on any "Could not load file or assembly" error:
1. `git status` the process folder — if `project.json`/`Main.xaml` show modified, check `git diff HEAD -- project.json`. Git often flags these as binary (encoding) — use `git show HEAD:<path>` piped to `diff` against the working copy instead of relying on `git diff` output directly.
2. If the working tree has undocumented dependency bumps, stash them (`git stash push -u -m "<reason>" -- Main.xaml project.json` — never discard outright) and retest with HEAD's committed versions first. It's a 2-minute test that can save an hour of NuGet archaeology.
3. Only chase NuGet cache corruption / explicit `UiPath.Platform` pinning if the pristine `develop` state ALSO reproduces the error.

Related: [[feedback_check_dependencylock_before_pr]], [[feedback_shared_root_dependencylock_conflicts]]
