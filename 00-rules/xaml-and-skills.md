# XAML, code and skills

## XAML edit protocol (no exceptions)
Before the FIRST read-for-edit or edit of any `.xaml`, `.cs` or `project.json` in a session:
1. `git branch --show-current`: you must NOT be on `develop`.
2. Invoke the skill `uipath:uipath-rpa`. Not optional, not skippable because the change "is one line".
3. Know whether the project is Modern/Windows or Legacy (`targetFramework` in `project.json`). Legacy projects are rejected by the CI check and cannot take new dependencies (`feedback_gusto_benefits_net45_dropped_legacy_incompatible`).

Other mandatory skills:
- Investigating a failure in Production or Staging: `benops-ticket-investigation` (reads logs before code) and `uipath:uipath-troubleshoot`.
- Orchestrator, queues, assets, jobs, libraries, triggers: `uipath:uipath-platform`.
- Before opening a PR: `/analyze`.
- After a skill is added or updated mid-session it is only recognized in a new session (`feedback_skill_registry_midsession_lag`).

The branch rule should also be enforced by a hook (see `../03-tools/hooks.md`); the skill rule is enforced only by this instruction, so do not rationalize around it.

## Read before you fix
- Read the whole `Main.xaml` and the failing path before editing a catch or state in a StateMachine (`feedback_deskcheck_before_fix_statemachine`).
- Find the first real error in the Orchestrator logs before touching code. A deploy or login symptom is often not where the cause is.
- Confirm the project GUID (`projectId` vs ProcessKey) before editing a "sibling" process: SAM vs SAMx, Kaiser vs Kaiser_CA (`feedback_verify_process_guid_before_editing_sibling`, `feedback_kaiser_ca_packetcollection_dead_duplicate_folder`).
- A local `InvokeWorkflowFile` can be dead (inside `CommentOut`) while a compiled activity from a lib is what really runs (`feedback_dead_invokeworkflowfile_vs_compiled_activity`).
- Fix the root cause, not the symptom. No features, refactors or abstractions beyond the task. Confirm before anything destructive or irreversible.

## Activity type verification (critical)
Never add an activity type (`ui:...`, `uix:...`) that does not already exist in the file or project. Before adding one:
```powershell
Select-String -Path ".\**\*.xaml" -Pattern "ui:ActivityName" -Recurse
```
If it is not found, stop and ask. Modern projects: check the exact activity and property names with `uip rpa` activity discovery instead of guessing.

## Libraries
- A bug specific to one process is fixed in that process, not in a shared library.
- If the root cause really is in a library (shared selector, login, SwitchToDelegatedAccount...), fix it in the library, in its OWN dedicated PR. A change in `Libraries/` affects every bot that consumes it.
  - Bump the lib `projectVersion` and its line in `dependencylock.json` in the same PR.
  - Align ALL the lib dependencies with the lock (strict check): `feedback_dependencylock_strict_no_skip_since_oct_2026`.
  - Consumers inherit the new minimums, so test the consuming bot end to end (Thomas asked for this).
  - Merge order: lib PR first, then the process PRs that bump to it. Check the feed before the process deploys.
- Never fix infrastructure problems (Python PATH, pwsh, Chrome, share access) inside Library XAML. Fix the machine.
- Reuse versions carefully: repackaging the same version with different content collides in the local NuGet cache and across Staging/Prod feeds (`feedback_local_nuget_cache_version_collision`, `feedback_library_version_collision_staging_prod`).

## Testing
- Tests always go through `uip or jobs start` in Staging (`feedback_orchestrator_job_trigger`), never against Production.
- Test data must be real and consistent, not borrowed or mixed (`feedback_test_data_must_be_real_not_borrowed`). Do not suffix fields with short limits; use a UUID (`feedback_staging_test_data_field_length`). Queue item format is Salesforce (`Group_Number__c`), never camelCase made up (`feedback_staging_queue_items`).
- `uip rpa pack` needs `--package-id` and a branch check first; if Helm needs .NET 10 use `uipcli.exe` (`reference_pack_with_uipcli_when_helm_needs_dotnet10`).
- Be honest in PRs and Jira about what was run end to end and what was not.
