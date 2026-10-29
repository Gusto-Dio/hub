# Buildkite and dependencies

Pipeline scripts live in `.buildkite/` of the repo: `check_dependency.sh`, `check_lock.sh`, `check_version.sh`, `update_dependency.sh`, `update_version.sh`, `deploy.ps1`, `pipeline.sh`, `slo_*.sh`. They change over time: read the ones in `origin/develop`, not the local checkout (`MSYS_NO_PATHCONV=1 git show origin/develop:.buildkite/check_dependency.sh` in Git Bash). A PR can pass its own CI and still fail the `develop` build if a new check landed in between (BT-77083, PR #3685).

## Before pushing a PR
1. Sync with develop so the diff only has ticket files. Buildkite uses `git diff origin/develop..HEAD` (two dots), so any process merged to develop after your branch started shows up and gets validated against your branch:
   ```
   git fetch origin develop
   git diff origin/develop..HEAD --name-only
   ```
   If files outside the ticket appear: `git merge origin/develop --no-edit`, then push.
2. `projectVersion` bumped in every changed project (`check_version.sh`: "can't be upgraded from X to X").
3. Every changed project (lib or process) has dependencies identical to `dependencylock.json`, exact string match including brackets (`[2.0.15]` is not `2.0.15`). No `skipTests` opt-out exists anymore. `jq` is not installed: validate with Python (`C:\Python314\python.exe -I` on the VDI, plain `python` on the VM). Edit `project.json` and the lock in bytes, preserve CRLF/BOM; git treats them as binary (`git diff --text`).
4. Bots under `Processes/` may depend only on `Gusto_*` libraries. UiPath.* and third-party packages must arrive through a lib. Before deleting a direct dep, confirm the XAML still compiles and that a consumed `Gusto_*` lib declares it at the same version (`unzip -p <lib>.nupkg '*.nuspec'`). `Libraries/` is exempt.
5. `targetFramework` must be Windows or Portable. A missing key means Legacy and is rejected.
6. A lib PR also bumps its own line in the root lock (`check_lock.sh`). The consuming process PR repeats the same lock line so it passes on its own.
7. The root `dependencylock.json` is shared: on a conflict take develop's version and re-bump yours (`feedback_shared_root_dependencylock_conflicts`).

Full stories: `feedback_dependencylock_strict_no_skip_since_oct_2026`, `feedback_bots_only_gusto_dependencies_check_since_28oct`, `feedback_check_dependencylock_before_pr`, `feedback_check_version_bump_before_pr`, `reference_check_version_checks_against_production`.

## Deploy behavior
- Buildkite auto-deploys ONLY Production, and only publishes the package to the feed. It never activates the Process. Staging is always manual (`uip or libraries upload` / `packages upload`).
- After a Production deploy, check `uip or processes list` (`ProcessVersion`): the Process can be several versions behind the feed. A rebind needs explicit approval and the real ProcessKey GUID.
- Libraries vs packages: `uip or libraries upload` for a project dependency, not `packages upload`.
- Intermittent failures that are retried, not "fixed": `FileLoadException ... 0x80131509` / "Collection was modified" (analyzer race), "Credentials file not found" (share access). Retry order for a lib + process pair: lib, confirm the feed in Production, then the process. A process that fails before its lib is on the feed gives `Cannot create unknown type AddLogFields`.
- `uip rpa pack` and the real uipcli rate analyzer rules differently (ST-SEC-008 is Error in one, Warning in the other).
- A failed deploy leaves Production unchanged. Fix with a new PR at version +1; do not edit the failed one in place.
