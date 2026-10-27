---
name: feedback_shared_root_dependencylock_conflicts
description: root-level dependencylock.json is shared by ALL processes in the repo — any two PRs bumping the same library will conflict there
metadata: 
  node_type: memory
  type: feedback
  originSessionId: efd7fa6f-09ff-4136-8bbb-9ca2069069c0
  modified: 2026-08-04T14:17:02.716Z
---

The repo has a single `dependencylock.json` at the **repo root** (not per-process) that pins exact versions for shared libraries like `Gusto_Benefits`. Any PR that bumps that library touches the same line/file, so two PRs bumping the same dependency to different versions around the same time will hit `mergeable_state: dirty` on this file specifically — git treats it as binary (can't line-merge), so it's always a hard conflict, never an auto-merge.

**Why:** discovered on BT-74721/BT-74718 (PRs #3024/#3025) — approved but conflicted because 13 unrelated Anthem PRs merged into `develop` bumped `Gusto_Benefits` from 1.554.1 to 1.555.1 for a different fix, while our PRs were still on 1.554.1.

**How to apply:**
- Before assuming a conflict means content is wrong, check whether the newer version on `develop` is a strict descendant commit of the version your PR is based on (`git merge-base --is-ancestor <your-fix-commit> <newer-commit>`) — if yes, the newer version is very likely a superset that includes your fix, safe to adopt.
- Verify by diffing the actual file your fix touched between your fix commit and current `develop` (not just the library's own commit log) — confirms no other commit silently reverted or touched it.
- Resolution: merge `origin/develop` into the PR branch, resolve `dependencylock.json` by taking develop's version (`git show origin/develop:dependencylock.json > dependencylock.json`), then bump the process's own `project.json` dependency version to match the lock (see [[feedback_check_dependency_before_pr]]-style rule) so Buildkite's `check_dependency.sh` doesn't fail on a stale reference.
- This will keep happening any time multiple in-flight PRs touch the same shared library — expect it, don't treat it as a sign the fix itself is broken.
